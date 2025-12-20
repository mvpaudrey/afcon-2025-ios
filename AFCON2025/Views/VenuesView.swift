import SwiftUI

struct VenuesView: View {
    let venues = [
        Venue(
            id: 1,
            name: "Ibn Batouta Stadium",
            city: "Tangier",
            capacity: "75,000",
            rating: 4.9,
            coordinates: "35.7595° N, 5.8340° W",
            description: "Morocco's largest stadium by capacity, flagship venue for AFCON 2025",
            facilities: ["VIP Lounges", "Media Center", "Underground Parking", "Premium Suites"],
            nearbyAttractions: ["Cave of Hercules", "Cape Spartel", "Tangier Medina"],
            contact: "+212 539 XX XX XX",
            website: "ibn-batouta-stadium.ma"
        ),
        Venue(
            id: 2,
            name: "Prince Moulay Abdellah Stadium",
            city: "Rabat",
            capacity: "68,700",
            rating: 4.8,
            coordinates: "34.0181° N, 6.8334° W",
            description: "National stadium of Morocco, hosting the opening match of AFCON 2025",
            facilities: ["Royal Box", "Media Center", "Training Grounds", "Museum"],
            nearbyAttractions: ["Royal Palace", "Kasbah of the Udayas", "Hassan Tower"],
            contact: "+212 537 XX XX XX",
            website: "prince-moulay-abdellah.ma"
        ),
        Venue(
            id: 3,
            name: "Mohammed V Stadium",
            city: "Casablanca",
            capacity: "45,000",
            rating: 4.7,
            coordinates: "33.5731° N, 7.5898° W",
            description: "Historic stadium in Morocco's economic capital, home to local giants",
            facilities: ["VIP Lounges", "Restaurants", "Corporate Boxes", "Fan Shop"],
            nearbyAttractions: ["Hassan II Mosque", "Old Medina", "Corniche Beach"],
            contact: "+212 522 XX XX XX",
            website: "mohammed-v-stadium.ma"
        ),
        Venue(
            id: 4,
            name: "Adrar Stadium",
            city: "Agadir",
            capacity: "45,000",
            rating: 4.6,
            coordinates: "30.4278° N, 9.5981° W",
            description: "Modern stadium in the coastal city, perfect for southern Morocco matches",
            facilities: ["Beach View Lounge", "Conference Center", "Parking", "Restaurants"],
            nearbyAttractions: ["Agadir Beach", "Souk El Had", "Agadir Kasbah"],
            contact: "+212 528 XX XX XX",
            website: "adrar-stadium.ma"
        ),
        Venue(
            id: 5,
            name: "Marrakesh Stadium",
            city: "Marrakesh",
            capacity: "45,000",
            rating: 4.8,
            coordinates: "31.6295° N, 7.9811° W",
            description: "Stunning stadium in the Red City with Atlas Mountains backdrop",
            facilities: ["Atlas View Terrace", "Traditional Restaurant", "VIP Areas", "Parking"],
            nearbyAttractions: ["Jemaa el-Fnaa", "Majorelle Garden", "Koutoubia Mosque"],
            contact: "+212 524 XX XX XX",
            website: "marrakesh-stadium.ma"
        ),
        Venue(
            id: 6,
            name: "Fez Stadium",
            city: "Fez",
            capacity: "45,000",
            rating: 4.5,
            coordinates: "34.0331° N, 5.0003° W",
            description: "Cultural capital's stadium, blending tradition with modern facilities",
            facilities: ["Cultural Center", "Traditional Crafts Shop", "VIP Lounges", "Parking"],
            nearbyAttractions: ["Fez Medina", "Al-Qarawiyyin University", "Bou Inania Madrasa"],
            contact: "+212 535 XX XX XX",
            website: "fez-stadium.ma"
        ),
        Venue(
            id: 7,
            name: "Moulay Hassan Stadium",
            city: "Rabat",
            capacity: "22,000",
            rating: 4.4,
            coordinates: "34.0205° N, 6.8416° W",
            description: "Intimate venue in the capital for smaller group stage matches",
            facilities: ["Executive Boxes", "Media Facilities", "Parking", "Refreshments"],
            nearbyAttractions: ["Mohammed V Mausoleum", "Oudaias Museum", "Andalusian Gardens"],
            contact: "+212 537 XX XX XX",
            website: "moulay-hassan-stadium.ma"
        ),
        Venue(
            id: 8,
            name: "Prince Moulay Abdellah Olympic Annex Stadium",
            city: "Rabat",
            capacity: "21,000",
            rating: 4.3,
            coordinates: "34.0165° N, 6.8298° W",
            description: "Secondary venue in Rabat, part of the Olympic complex",
            facilities: ["Olympic Museum", "Training Facilities", "Medical Center", "Parking"],
            nearbyAttractions: ["Olympic Complex", "Temara Beach", "National Library"],
            contact: "+212 537 XX XX XX",
            website: "olympic-annex-rabat.ma"
        ),
        Venue(
            id: 9,
            name: "Al Barid Stadium",
            city: "Rabat",
            capacity: "18,000",
            rating: 4.2,
            coordinates: "34.0142° N, 6.8445° W",
            description: "Compact modern stadium providing intimate match experience",
            facilities: ["Modern Amenities", "Fan Zone", "Corporate Facilities", "Parking"],
            nearbyAttractions: ["Bouregreg Marina", "Sale Medina", "Rabat Zoo"],
            contact: "+212 537 XX XX XX",
            website: "al-barid-stadium.ma"
        )
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                HStack {
                    Image(systemName: "mappin")
                        .foregroundColor(Color("moroccoRed"))
                    Text(LocalizedStringKey("Stadium & Venues"))
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)

                // Interactive Map Placeholder
                MapPlaceholder()

                // Venue Cards
                LazyVStack(spacing: 16) {
                    ForEach(venues, id: \.id) { venue in
                        VenueCard(venue: venue)
                    }
                }
            }
            .padding()
        }
    }
}

struct MapPlaceholder: View {
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color("moroccoRed").opacity(0.1),
                            Color("moroccoGreen").opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 200)

                VStack(spacing: 8) {
                    Image(systemName: "mappin")
                        .font(.largeTitle)
                        .foregroundColor(Color("moroccoRed"))

                    VStack(spacing: 4) {
                        Text(LocalizedStringKey("Interactive Map"))
                            .font(.headline)
                        Text(LocalizedStringKey("View all stadium locations across Morocco"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // Open full map action
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "location")
                                    .font(.caption)
                                Text(LocalizedStringKey("Open Full Map"))
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color("moroccoRed"))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .padding()
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct VenueCard: View {
    let venue: Venue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(venue.name)
                            .font(.headline)
                            .foregroundColor(Color("moroccoRed"))
                        Text(venue.city)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(venue.capacity)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color("moroccoGreen").opacity(0.1))
                        .foregroundColor(Color("moroccoGreen"))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color("moroccoGreen"), lineWidth: 1)
                        )
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(venue.rating, specifier: "%.1f")")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            // Description
            Text(venue.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)

            // Facilities
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey("Facilities"))
                    .font(.caption)
                    .fontWeight(.medium)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 2) {
                    ForEach(venue.facilities, id: \.self) { facility in
                        Text(facility)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(3)
                    }
                }
            }

            // Nearby Attractions
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey("Nearby Attractions"))
                    .font(.caption)
                    .fontWeight(.medium)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 2) {
                    ForEach(venue.nearbyAttractions, id: \.self) { attraction in
                        Text(attraction)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color("moroccoGreen").opacity(0.1))
                            .foregroundColor(Color("moroccoGreen"))
                            .cornerRadius(3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color("moroccoGreen"), lineWidth: 0.5)
                            )
                    }
                }
            }

            // Contact Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "phone")
                        .font(.caption2)
                    Text(venue.contact)
                        .font(.caption2)
                }

                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.caption2)
                    Text(venue.website)
                        .font(.caption2)
                }
            }
            .foregroundColor(.secondary)

            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    // Directions action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(LocalizedStringKey("Directions"))
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    // View details action
                }) {
                    Text(LocalizedStringKey("View Details"))
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("moroccoRed"))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Data Models
struct Venue {
    let id: Int
    let name: String
    let city: String
    let capacity: String
    let rating: Double
    let coordinates: String
    let description: String
    let facilities: [String]
    let nearbyAttractions: [String]
    let contact: String
    let website: String
}

#Preview {
    VenuesView()
}