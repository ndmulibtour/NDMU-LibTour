class TourSection {
  final String title;
  final String sceneId;

  TourSection({required this.title, required this.sceneId});
}

class FloorData {
  final String floorName;
  final List<TourSection> sections;

  FloorData({required this.floorName, required this.sections});
}

final List<FloorData> libraryFloors = [
  FloorData(
    floorName: "University Library",
    sections: [
      TourSection(title: "NDMU Library", sceneId: "6978265df7083ba3665904a6"),
    ],
  ),
  FloorData(
    floorName: "1st Floor",
    sections: [
      TourSection(
          title: "Library Entrance", sceneId: "697825f6f7083bc155590495"),
      TourSection(
          title: "CSCAM & Archives", sceneId: "6978296b70f11a7b5a1085f6"),
      TourSection(
          title: "Law School Library", sceneId: "697858a270f11a45ea108937"),
      TourSection(
          title: "Graduate School Library",
          sceneId: "697863c0f7083b566c5908c8"),
      TourSection(title: "EMC", sceneId: "6978668770f11a701b108aaa"),
    ],
  ),
  FloorData(
    floorName: "2nd Floor",
    sections: [
      TourSection(
          title: "Filipiniana Section", sceneId: "6982e78b9da68288a5139bef"),
      TourSection(
          title: "Director of Libraries", sceneId: "6982f3539da68242ef139c80"),
      TourSection(
          title: "Technical Section", sceneId: "6982f3539822ba02d869d6d8"),
      TourSection(
          title: "Internet Section", sceneId: "6982f3769822ba124369d6db"),
    ],
  ),
  FloorData(
    floorName: "3rd Floor",
    sections: [
      TourSection(title: "Main Section", sceneId: "6982f9b89822ba2cbf69d736"),
      TourSection(
          title: "Discussion Room", sceneId: "698307b16fccac7e5ec6d72d"),
    ],
  ),
];
