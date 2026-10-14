enum ReportPublicationState {
  published('Published'),
  pendingUpload('Pending upload'),
  failed('Failed');

  const ReportPublicationState(this.label);
  final String label;
}
