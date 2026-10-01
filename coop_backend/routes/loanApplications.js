const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Get all loan applications
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, member_name as applicantName, amount, status, date_submitted as dateSubmitted, loan_type as purpose FROM loan_applications ORDER BY date_submitted DESC'
    );
    res.json(rows);
  } catch (error) {
    console.error('Error fetching loan applications:', error);
    res.status(500).json({ error: 'Failed to fetch loan applications' });
  }
});

// Get single loan application by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await pool.query(
      'SELECT id, member_name as applicantName, amount, status, date_submitted as dateSubmitted, loan_type as purpose, income, credit_score as creditScore FROM loan_applications WHERE id = ?',
      [id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Loan application not found' });
    }
    
    res.json(rows[0]);
  } catch (error) {
    console.error('Error fetching loan application:', error);
    res.status(500).json({ error: 'Failed to fetch loan application' });
  }
});

// Create new loan application
router.post('/', async (req, res) => {
  try {
    const { applicantName, amount, purpose, income, creditScore } = req.body;
    
    // Generate application ID
    const applicationId = `LA-2025-${String(Math.floor(Math.random() * 9000) + 1000)}`;
    
    const [result] = await pool.query(
      'INSERT INTO loan_applications (application_id, member_id, member_name, loan_type, amount, purpose, status, income, credit_score, date_submitted) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [applicationId, 1, applicantName, purpose, amount, purpose, 'pending', income, creditScore, new Date().toISOString().split('T')[0]]
    );
    
    const [newApplication] = await pool.query(
      'SELECT id, member_name as applicantName, amount, status, date_submitted as dateSubmitted, loan_type as purpose, income, credit_score as creditScore FROM loan_applications WHERE id = ?',
      [result.insertId]
    );
    
    res.status(201).json(newApplication[0]);
  } catch (error) {
    console.error('Error creating loan application:', error);
    res.status(500).json({ error: 'Failed to create loan application' });
  }
});

// Update loan application status
router.patch('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    await pool.query(
      'UPDATE loan_applications SET status = ? WHERE id = ?',
      [status, id]
    );
    
    const [updatedApplication] = await pool.query(
      'SELECT id, member_name as applicantName, amount, status, date_submitted as dateSubmitted, loan_type as purpose FROM loan_applications WHERE id = ?',
      [id]
    );
    
    if (updatedApplication.length === 0) {
      return res.status(404).json({ error: 'Loan application not found' });
    }
    
    res.json(updatedApplication[0]);
  } catch (error) {
    console.error('Error updating loan application:', error);
    res.status(500).json({ error: 'Failed to update loan application' });
  }
});

module.exports = router;