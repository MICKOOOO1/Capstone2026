import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'app_bottom_navigation_bar.dart';

class Loan {
  final String id;
  final String loanType;
  final String principal;
  final String disbursementDate;
  final List<PaymentSchedule> amortizationSchedule;

  Loan({
    required this.id,
    required this.loanType,
    required this.principal,
    required this.disbursementDate,
    required this.amortizationSchedule,
  });

  double get principalAmount => _parseCurrency(principal);

  String get monthlyPayment => amortizationSchedule.isEmpty
      ? '₱0.00'
      : amortizationSchedule.first.amount;

  double get totalRepayable => _amountFor(amortizationSchedule);

  double get amountPaid => _amountFor(
    amortizationSchedule.where(
      (payment) => payment.status == PaymentStatus.completed,
    ),
  );

  double get outstandingBalance =>
      (totalRepayable - amountPaid).clamp(0.0, double.infinity);

  double get totalInterest => totalRepayable - principalAmount;

  double get interestPaid =>
      totalRepayable == 0 ? 0 : totalInterest * amountPaid / totalRepayable;

  int get remainingMonths => amortizationSchedule
      .where((payment) => payment.status != PaymentStatus.completed)
      .length;

  int get totalMonths => amortizationSchedule.length;

  double get paymentProgress =>
      totalRepayable == 0 ? 0 : amountPaid / totalRepayable;
}

double _parseCurrency(String amount) {
  return double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
}

String _formatCurrency(double amount) => '₱${amount.toStringAsFixed(2)}';

double _amountFor(Iterable<PaymentSchedule> payments) {
  return payments.fold(
    0,
    (sum, payment) => sum + _parseCurrency(payment.amount),
  );
}

class LoanDetailsScreen extends StatefulWidget {
  const LoanDetailsScreen({super.key});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Loan> _loans = [
    Loan(
      id: '1',
      loanType: 'REGULAR LOAN',
      principal: '₱80,000.00',
      disbursementDate: 'May 15, 2025',
      amortizationSchedule: [
        PaymentSchedule(
          month: 1,
          date: 'Jun 15, 2025',
          amount: '₱8,266.67',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 2,
          date: 'Jul 15, 2025',
          amount: '₱8,266.67',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 3,
          date: 'Aug 15, 2025',
          amount: '₱8,266.67',
          status: PaymentStatus.current,
        ),
        PaymentSchedule(
          month: 4,
          date: 'Sep 15, 2025',
          amount: '₱8,266.67',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 5,
          date: 'Oct 15, 2025',
          amount: '₱8,266.67',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 6,
          date: 'Nov 15, 2025',
          amount: '₱8,266.67',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 7,
          date: 'Dec 15, 2025',
          amount: '₱8,266.67',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 8,
          date: 'Jan 15, 2026',
          amount: '₱8,266.67',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 9,
          date: 'Feb 15, 2026',
          amount: '₱8,266.67',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 10,
          date: 'Mar 15, 2026',
          amount: '₱8,266.67',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 11,
          date: 'Apr 15, 2026',
          amount: '₱8,266.67',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 12,
          date: 'May 15, 2026',
          amount: '₱8,266.67',
          status: PaymentStatus.future,
        ),
      ],
    ),
    Loan(
      id: '2',
      loanType: 'EDUCATIONAL LOAN',
      principal: '₱50,000.00',
      disbursementDate: 'Mar 10, 2025',
      amortizationSchedule: [
        PaymentSchedule(
          month: 1,
          date: 'Apr 10, 2025',
          amount: '₱4,150.00',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 2,
          date: 'May 10, 2025',
          amount: '₱4,150.00',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 3,
          date: 'Jun 10, 2025',
          amount: '₱4,150.00',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 4,
          date: 'Jul 10, 2025',
          amount: '₱4,150.00',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 5,
          date: 'Aug 10, 2025',
          amount: '₱4,150.00',
          status: PaymentStatus.current,
        ),
        PaymentSchedule(
          month: 6,
          date: 'Sep 10, 2025',
          amount: '₱4,150.00',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 7,
          date: 'Oct 10, 2025',
          amount: '₱4,150.00',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 8,
          date: 'Nov 10, 2025',
          amount: '₱4,150.00',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 9,
          date: 'Dec 10, 2025',
          amount: '₱4,150.00',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 10,
          date: 'Jan 10, 2026',
          amount: '₱4,150.00',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 11,
          date: 'Feb 10, 2026',
          amount: '₱4,150.00',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 12,
          date: 'Mar 10, 2026',
          amount: '₱4,150.00',
          status: PaymentStatus.future,
        ),
      ],
    ),
    Loan(
      id: '3',
      loanType: 'EMERGENCY LOAN',
      principal: '₱20,000.00',
      disbursementDate: 'Jan 5, 2025',
      amortizationSchedule: [
        PaymentSchedule(
          month: 1,
          date: 'Feb 5, 2025',
          amount: '₱2,500.00',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 2,
          date: 'Mar 5, 2025',
          amount: '₱2,500.00',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 3,
          date: 'Apr 5, 2025',
          amount: '₱2,500.00',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 4,
          date: 'May 5, 2025',
          amount: '₱2,500.00',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 5,
          date: 'Jun 5, 2025',
          amount: '₱2,500.00',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 6,
          date: 'Jul 5, 2025',
          amount: '₱2,500.00',
          status: PaymentStatus.completed,
        ),
        PaymentSchedule(
          month: 7,
          date: 'Aug 5, 2025',
          amount: '₱2,500.00',
          status: PaymentStatus.current,
        ),
        PaymentSchedule(
          month: 8,
          date: 'Sep 5, 2025',
          amount: '₱2,500.00',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 9,
          date: 'Oct 5, 2025',
          amount: '₱2,500.00',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 10,
          date: 'Nov 5, 2025',
          amount: '₱2,500.00',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 11,
          date: 'Dec 5, 2025',
          amount: '₱2,500.00',
          status: PaymentStatus.future,
        ),
        PaymentSchedule(
          month: 12,
          date: 'Jan 5, 2026',
          amount: '₱2,500.00',
          status: PaymentStatus.future,
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const LoanDetailsAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: _loans.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: LoanSummaryCard(
                              loan: _loans[index],
                              currentIndex: index,
                              totalLoans: _loans.length,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    LoanPageIndicator(
                      currentPage: _currentPage,
                      totalLoans: _loans.length,
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        key: ValueKey(_currentPage),
                        children: [
                          Expanded(
                            child: LoanInfoCard(
                              label: 'Monthly Payment',
                              amount: _loans[_currentPage].monthlyPayment,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingL),
                          Expanded(
                            child: LoanInfoCard(
                              label: 'Outstanding Balance',
                              amount: _formatCurrency(
                                _loans[_currentPage].outstandingBalance,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: LoanProgressCard(
                        key: ValueKey('progress_$_currentPage'),
                        loan: _loans[_currentPage],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: AmortizationScheduleCard(
                        key: ValueKey('schedule_$_currentPage'),
                        payments: _loans[_currentPage].amortizationSchedule,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppBottomNavigationBar(currentIndex: 0, parentContext: context),
          ],
        ),
      ),
    );
  }
}

class LoanDetailsAppBar extends StatelessWidget {
  const LoanDetailsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      decoration: const BoxDecoration(color: AppTheme.cardWhite),
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.backButtonBg,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.darkText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          const Expanded(
            child: Text(
              'Loan Details',
              style: TextStyle(
                color: AppTheme.darkText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoanSummaryCard extends StatelessWidget {
  final Loan loan;
  final int currentIndex;
  final int totalLoans;

  const LoanSummaryCard({
    super.key,
    required this.loan,
    required this.currentIndex,
    required this.totalLoans,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.elevatedCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loan.loanType,
                style: const TextStyle(
                  color: AppTheme.lightGreenText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${currentIndex + 1} of $totalLoans',
                style: const TextStyle(
                  color: AppTheme.accentGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            loan.principal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Original Loan Amount',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Disbursed ${loan.disbursementDate}',
            style: const TextStyle(
              color: AppTheme.lightGrayGreen,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: loan.paymentProgress,
                        backgroundColor: const Color(0xFF1A5A35),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.accentGold,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Text(
                '${(loan.paymentProgress * 100).round()}% paid',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LoanInfoCard extends StatelessWidget {
  final String label;
  final String amount;

  const LoanInfoCard({super.key, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedGray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            amount,
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class LoanProgressCard extends StatelessWidget {
  final Loan loan;

  const LoanProgressCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loan Progress',
            style: TextStyle(
              color: AppTheme.darkText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildProgressRow(
            'Amount Paid',
            _formatCurrency(loan.amountPaid),
            emphasizeValue: true,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildProgressRow(
            'Total Repayable',
            _formatCurrency(loan.totalRepayable),
            emphasizeValue: true,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildProgressRow(
            'Outstanding Balance',
            '${_formatCurrency(loan.outstandingBalance)} Including interest',
            emphasizeValue: true,
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Text(
            'Payment Progress',
            style: TextStyle(
              color: AppTheme.mutedGray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${_formatCurrency(loan.amountPaid)} Paid / ${_formatCurrency(loan.totalRepayable)} Total',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: loan.paymentProgress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.timelineGray,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryGreen,
              ),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildProgressRow(
            'Interest',
            '${_formatCurrency(loan.interestPaid)} paid / ${_formatCurrency(loan.totalInterest)} total',
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildProgressRow(
            'Remaining Term',
            '${loan.remainingMonths} months left / ${loan.totalMonths} months',
            emphasizeValue: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    String label,
    String value, {
    bool emphasizeValue = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.mutedGray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: emphasizeValue ? 16 : 14,
              fontWeight: emphasizeValue ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class AmortizationScheduleCard extends StatelessWidget {
  final List<PaymentSchedule> payments;

  const AmortizationScheduleCard({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AMORTIZATION SCHEDULE',
            style: TextStyle(
              color: AppTheme.mutedGray,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ...payments.asMap().entries.map((entry) {
            final index = entry.key;
            final payment = entry.value;
            final isLast = index == payments.length - 1;
            return Column(
              children: [
                TimelineItem(payment: payment, showConnector: !isLast),
                if (!isLast) const SizedBox(height: AppTheme.spacingS),
              ],
            );
          }),
        ],
      ),
    );
  }
}

enum PaymentStatus { completed, current, future }

class PaymentSchedule {
  final int month;
  final String date;
  final String amount;
  final PaymentStatus status;

  PaymentSchedule({
    required this.month,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class TimelineItem extends StatelessWidget {
  final PaymentSchedule payment;
  final bool showConnector;

  const TimelineItem({
    super.key,
    required this.payment,
    required this.showConnector,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildIndicator(),
            if (showConnector)
              Container(
                width: 2,
                height: 40,
                color: payment.status == PaymentStatus.completed
                    ? AppTheme.timelineGray
                    : AppTheme.timelineGray,
              ),
          ],
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(child: _buildContent()),
        const SizedBox(width: AppTheme.spacingM),
        _buildAmount(),
      ],
    );
  }

  Widget _buildIndicator() {
    switch (payment.status) {
      case PaymentStatus.completed:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppTheme.completedGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        );
      case PaymentStatus.current:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentGold, width: 2),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentGold,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NEXT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      case PaymentStatus.future:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.timelineGray, width: 2),
          ),
        );
    }
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Month ${payment.month}',
          style: TextStyle(
            color: payment.status == PaymentStatus.completed
                ? AppTheme.mutedGray
                : AppTheme.primaryText,
            fontSize: 14,
            fontWeight: payment.status == PaymentStatus.current
                ? FontWeight.w700
                : FontWeight.w500,
            decoration: payment.status == PaymentStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          payment.date,
          style: TextStyle(
            color: payment.status == PaymentStatus.completed
                ? AppTheme.mutedGray
                : AppTheme.mutedGray,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            decoration: payment.status == PaymentStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAmount() {
    return Text(
      payment.amount,
      style: TextStyle(
        color: payment.status == PaymentStatus.completed
            ? AppTheme.mutedGray
            : AppTheme.primaryText,
        fontSize: 14,
        fontWeight: payment.status == PaymentStatus.current
            ? FontWeight.w700
            : FontWeight.w500,
        decoration: payment.status == PaymentStatus.completed
            ? TextDecoration.lineThrough
            : null,
      ),
    );
  }
}

class LoanPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalLoans;

  const LoanPageIndicator({
    super.key,
    required this.currentPage,
    required this.totalLoans,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalLoans,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? AppTheme.accentGold
                : AppTheme.timelineGray,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
