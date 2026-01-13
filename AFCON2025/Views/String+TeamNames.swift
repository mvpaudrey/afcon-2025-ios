//
//  String+TeamNames.swift
//  AFCON2025
//
//  Created by Audrey Zebaze on 24/12/2025.
//

import Foundation

// MARK: - Localization helpers

func localizedTeamName(_ name: String) -> String {
    let language = Locale.current.language.languageCode?.identifier ?? Locale.current.languageCode ?? "fr"

    switch language {
    case "fr":
        return frenchTeamNames[name] ?? name
    case "ar":
        return arabicTeamNames[name] ?? name
    default:
        return name
    }
}

private let frenchTeamNames: [String: String] = [
    "Morocco": "Maroc",
    "Senegal": "Sénégal",
    "Algeria": "Algérie",
    "Tunisia": "Tunisie",
    "Egypt": "Égypte",
    "Nigeria": "Nigeria",
    "Cameroon": "Cameroun",
    "Ghana": "Ghana",
    "Ivory Coast": "Côte d'Ivoire",
    "Cote d'Ivoire": "Côte d'Ivoire",
    "Côte d'Ivoire": "Côte d'Ivoire",
    "South Africa": "Afrique du Sud",
    "Mali": "Mali",
    "Burkina Faso": "Burkina Faso",
    "Guinea": "Guinée",
    "Guinea-Bissau": "Guinée-Bissau",
    "Equatorial Guinea": "Guinée équatoriale",
    "Gabon": "Gabon",
    "Angola": "Angola",
    "Zambia": "Zambie",
    "Zimbabwe": "Zimbabwe",
    "Tanzania": "Tanzanie",
    "Comoros": "Comores",
    "Botswana": "Botswana",
    "Benin": "Bénin",
    "Uganda": "Ouganda",
    "Mozambique": "Mozambique",
    "DR Congo": "RD Congo",
    "Congo DR": "RD Congo",
    "Democratic Republic of the Congo": "RD Congo",
    "Sudan": "Soudan"
]

private let arabicTeamNames: [String: String] = [
    "Morocco": "المغرب",
    "Senegal": "السنغال",
    "Algeria": "الجزائر",
    "Tunisia": "تونس",
    "Egypt": "مصر",
    "Nigeria": "نيجيريا",
    "Cameroon": "الكاميرون",
    "Ghana": "غانا",
    "Ivory Coast": "كوت ديفوار",
    "Cote d'Ivoire": "كوت ديفوار",
    "Côte d'Ivoire": "كوت ديفوار",
    "South Africa": "جنوب أفريقيا",
    "Mali": "مالي",
    "Burkina Faso": "بوركينا فاسو",
    "Guinea": "غينيا",
    "Guinea-Bissau": "غينيا بيساو",
    "Equatorial Guinea": "غينيا الاستوائية",
    "Gabon": "الغابون",
    "Angola": "أنغولا",
    "Zambia": "زامبيا",
    "Zimbabwe": "زيمبابوي",
    "Tanzania": "تنزانيا",
    "Comoros": "جزر القمر",
    "Botswana": "بوتسوانا",
    "Benin": "بنين",
    "Uganda": "أوغندا",
    "Mozambique": "موزمبيق",
    "DR Congo": "جمهورية الكونغو الديمقراطية",
    "Congo DR": "جمهورية الكونغو الديمقراطية",
    "Democratic Republic of the Congo": "جمهورية الكونغو الديمقراطية",
    "Sudan": "السودان"
]
