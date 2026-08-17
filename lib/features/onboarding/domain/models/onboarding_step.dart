/// Copy for one onboarding page — exact strings from Jira SUBAPPS-129 §6.
class OnboardingStep {
  const OnboardingStep({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

const onboardingSteps = [
  OnboardingStep(
    title: 'Scan documents in seconds',
    subtitle: 'Turn paper, receipts, notes, and IDs into clean digital files.',
  ),
  OnboardingStep(
    title: 'Edit like an expert',
    subtitle:
        'Crop, enhance, sign, merge, and organize your scans with powerful tools.',
  ),
  OnboardingStep(
    title: 'Export anywhere',
    subtitle: 'Save as PDF, JPG, PNG, or recognized text whenever you need.',
  ),
];
