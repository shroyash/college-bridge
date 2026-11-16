/// Faculty enum matching the Spring Boot backend Faculty enum.
enum Faculty {
  bca('BCA'),
  bba('BBA'),
  bscCsit('BSC_CSIT'),
  bim('BIM'),
  bhm('BHM');

  final String value;
  const Faculty(this.value);

  static Faculty fromString(String s) =>
      Faculty.values.firstWhere((f) => f.value == s);

  String get displayName => switch (this) {
        Faculty.bca => 'BCA',
        Faculty.bba => 'BBA',
        Faculty.bscCsit => 'BSc CSIT',
        Faculty.bim => 'BIM',
        Faculty.bhm => 'BHM',
      };
}
