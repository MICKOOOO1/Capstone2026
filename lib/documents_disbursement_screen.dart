import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'application_summary_screen.dart';
import 'loan_calculator_service.dart';

class DocumentsDisbursementScreen extends StatefulWidget {
  final double loanAmount;
  final LoanType loanType;
  final int tenure;
  final LoanComputation computation;

  const DocumentsDisbursementScreen({
    super.key,
    this.loanAmount = 50000.0,
    required this.loanType,
    required this.tenure,
    required this.computation,
  });

  @override
  State<DocumentsDisbursementScreen> createState() =>
      _DocumentsDisbursementScreenState();
}

class _DocumentsDisbursementScreenState
    extends State<DocumentsDisbursementScreen> {
  String? _payslipFileName;
  String? _idFileName;
  String? _collateralFileName;
  String? _otherFileName;

  bool get _isCollateralRequired => widget.loanAmount > 200000;

  bool get _isValidated {
    if (_payslipFileName == null || _idFileName == null) return false;
    if (_isCollateralRequired && _collateralFileName == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F4),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoanProgressIndicator(currentStep: 1),
              const SizedBox(height: AppTheme.spacingL),
              const Text(
                'UPLOAD REQUIREMENTS',
                style: TextStyle(
                  color: Color(0xFF7D8A82),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              UploadRequirementCard(
                title: 'Pay Slip *',
                subtitle: 'Latest payslip (within 3 months)',
                fileName: _payslipFileName,
                onUpload: (fileName) {
                  setState(() {
                    _payslipFileName = fileName;
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              UploadRequirementCard(
                title: 'Valid Identification *',
                subtitle: 'Government-issued photo ID',
                fileName: _idFileName,
                onUpload: (fileName) {
                  setState(() {
                    _idFileName = fileName;
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              UploadRequirementCard(
                title: 'Collateral Document',
                subtitle: _isCollateralRequired
                    ? 'Required for loans over ₱200,000'
                    : 'Optional (required for loans over ₱200,000)',
                fileName: _collateralFileName,
                isRequired: _isCollateralRequired,
                onUpload: (fileName) {
                  setState(() {
                    _collateralFileName = fileName;
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              UploadRequirementCard(
                title: 'Other Supporting Documents',
                subtitle: 'Optional additional documents',
                fileName: _otherFileName,
                isRequired: false,
                onUpload: (fileName) {
                  setState(() {
                    _otherFileName = fileName;
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),
              PrimaryButton(
                isEnabled: _isValidated,
                onPressed: _isValidated
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApplicationSummaryScreen(
                              loanAmount: widget.loanAmount,
                              loanType: widget.loanType,
                              tenure: widget.tenure,
                              computation: widget.computation,
                              payslipFileName: _payslipFileName!,
                              idFileName: _idFileName!,
                              collateralFileName: _collateralFileName,
                              otherFileName: _otherFileName,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
              const SizedBox(height: AppTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.cardWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppTheme.mutedGray,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Documents & Disbursement',
        style: TextStyle(
          color: Color(0xFF183A24),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
    );
  }
}

class LoanProgressIndicator extends StatelessWidget {
  final int currentStep;

  const LoanProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStep('Loan Details', 0, currentStep),
        Expanded(
          child: Container(
            height: 2,
            color: currentStep >= 0
                ? AppTheme.primaryGreen
                : const Color(0xFFE0E0E0),
          ),
        ),
        _buildStep('Documents', 1, currentStep),
        Expanded(
          child: Container(
            height: 2,
            color: currentStep >= 1
                ? AppTheme.primaryGreen
                : const Color(0xFFE0E0E0),
          ),
        ),
        _buildStep('Review', 2, currentStep),
      ],
    );
  }

  Widget _buildStep(String label, int step, int currentStep) {
    final isActive = step == currentStep;
    final isCompleted = step < currentStep;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? AppTheme.primaryGreen
                : const Color(0xFFE0E0E0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive || isCompleted
                ? AppTheme.primaryGreen
                : const Color(0xFF7D8A82),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class UploadRequirementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? fileName;
  final bool isRequired;
  final ValueChanged<String> onUpload;

  const UploadRequirementCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.fileName,
    this.isRequired = true,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Simulate file picker - in production, use file_picker package
        // For now, simulate a successful upload
        final simulatedFileName =
            '${title.replaceAll(' *', '').replaceAll(' ', '_')}_uploaded.pdf';
        onUpload(simulatedFileName);
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: fileName != null
                    ? AppTheme.primaryGreen.withOpacity(0.1)
                    : const Color(0xFFF3F5F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                fileName != null
                    ? Icons.check_circle
                    : Icons.cloud_upload_outlined,
                color: fileName != null
                    ? AppTheme.primaryGreen
                    : const Color(0xFF7D8A82),
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF183A24),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName ?? subtitle,
                    style: TextStyle(
                      color: fileName != null
                          ? AppTheme.primaryGreen
                          : const Color(0xFF7D8A82),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF7D8A82),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.isEnabled, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? AppTheme.primaryGreen
              : const Color(0xFFB8C4B8),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Continue to Review',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
