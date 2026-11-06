const express = require('express');
const crypto = require('node:crypto');
const pool = require('../config/database');

const router = express.Router();
const validStatuses = new Set(['pending', 'under review', 'approved', 'rejected', 'released', 'completed', 'overdue']);

function normalizeStatus(status = 'pending') {
  return String(status).trim().toLowerCase();
}

function normalizeLoanType(type = 'Regular') {
  const value = String(type).trim();
  const allowed = ['Regular', 'Medical', 'Educational', 'Emergency', 'Business'];
  return allowed.includes(value) ? value : 'Regular';
}

const selectLoanApplications = `
  SELECT
    la.id,
    m.member_id AS memberId,
    m.membership_type AS membershipType,
    la.member_name AS applicantName,
    la.amount,
    la.status,
    la.date_submitted AS dateSubmitted,
    la.loan_type AS purpose,
    la.income,
    la.credit_score AS creditScore
  FROM loan_applications la
  JOIN members m ON m.id = la.member_id
`;

function canonicalJson(value) {
  if (Array.isArray(value)) {
    return `[${value.map(canonicalJson).join(',')}]`;
  }
  if (typeof value === 'object' && value !== null) {
    return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${canonicalJson(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

async function authorizeLoanStatusUpdate(req, res, next) {
  const supabaseUrl = process.env.SUPABASE_URL;
  const publishableKey = process.env.SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_ANON_KEY;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const token = req.headers.authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  const grantToken = req.body.grant_token;
  const status = normalizeStatus(req.body.status);

  if (!validStatuses.has(status)) {
    res.status(400).json({ error: 'Invalid loan application status' });
    return;
  }
  if (!supabaseUrl || !publishableKey || !serviceRoleKey) {
    res.status(503).json({ error: 'Secure loan updates are not configured' });
    return;
  }
  if (!token || !grantToken) {
    res.status(401).json({ error: 'Authenticated action authorization is required' });
    return;
  }

  try {
    const authResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: {
        apikey: publishableKey,
        Authorization: `Bearer ${token}`,
      },
    });
    if (!authResponse.ok) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }
    const user = await authResponse.json();
    if (user.app_metadata?.role !== 'super_admin') {
      res.status(403).json({ error: 'Super Admin access required' });
      return;
    }

    const fingerprint = crypto
      .createHash('sha256')
      .update(canonicalJson({ status }))
      .digest('hex');
    const grantResponse = await fetch(
      `${supabaseUrl}/rest/v1/rpc/consume_admin_action_grant`,
      {
        method: 'POST',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          p_user_id: user.id,
          p_action_name: 'update-loan-status',
          p_target_id: String(req.params.id),
          p_request_fingerprint: fingerprint,
          p_grant_token_hash: crypto
            .createHash('sha256')
            .update(grantToken)
            .digest('hex'),
        }),
      }
    );
    if (!grantResponse.ok) {
      res.status(503).json({ error: 'Unable to validate action authorization' });
      return;
    }
    if ((await grantResponse.json()) !== true) {
      res.status(403).json({ error: 'Action authorization is invalid or expired' });
      return;
    }

    req.authorizedLoanStatus = status;
    next();
  } catch (error) {
    next(error);
  }
}

router.get('/', async (req, res, next) => {
  try {
    const [rows] = await pool.query(`${selectLoanApplications} ORDER BY la.date_submitted DESC, la.id DESC`);
    res.json(rows);
  } catch (error) {
    next(error);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const [rows] = await pool.query(`${selectLoanApplications} WHERE la.id = ?`, [req.params.id]);

    if (rows.length === 0) {
      res.status(404).json({ error: 'Loan application not found' });
      return;
    }

    res.json(rows[0]);
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const applicantName = String(req.body.applicantName || '').trim();
    const amount = Number(req.body.amount);
    const purpose = normalizeLoanType(req.body.purpose);
    const status = normalizeStatus(req.body.status);
    const income = req.body.income == null ? null : Number(req.body.income);
    const creditScore = req.body.creditScore == null ? null : Number(req.body.creditScore);

    if (!applicantName || !Number.isFinite(amount) || amount <= 0) {
      res.status(400).json({ error: 'applicantName and a positive amount are required' });
      return;
    }

    if (!validStatuses.has(status)) {
      res.status(400).json({ error: 'Invalid loan application status' });
      return;
    }

    const connection = await pool.getConnection();

    try {
      await connection.beginTransaction();

      const memberCode = `M-${Date.now()}`;
      const [memberResult] = await connection.query(
        'INSERT INTO members (member_id, first_name, last_name) VALUES (?, ?, ?)',
        [memberCode, applicantName, '']
      );

      const [result] = await connection.query(
        `INSERT INTO loan_applications
          (application_id, member_id, member_name, loan_type, amount, purpose, status, income, credit_score, date_submitted)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURDATE())`,
        [`LA-${Date.now()}`, memberResult.insertId, applicantName, purpose, amount, purpose, status, income, creditScore]
      );

      const [created] = await connection.query(`${selectLoanApplications} WHERE la.id = ?`, [result.insertId]);
      await connection.commit();
      res.status(201).json(created[0]);
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  } catch (error) {
    next(error);
  }
});

router.patch('/:id', authorizeLoanStatusUpdate, async (req, res, next) => {
  try {
    const status = req.authorizedLoanStatus;

    const [result] = await pool.query('UPDATE loan_applications SET status = ? WHERE id = ?', [status, req.params.id]);

    if (result.affectedRows === 0) {
      res.status(404).json({ error: 'Loan application not found' });
      return;
    }

    const [updated] = await pool.query(`${selectLoanApplications} WHERE la.id = ?`, [req.params.id]);
    res.json(updated[0]);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
