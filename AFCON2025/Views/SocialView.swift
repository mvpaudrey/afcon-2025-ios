import SwiftUI

struct SocialView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(Color("moroccoRed"))
                Text("Social & Tourism")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()

            // Custom Tab Picker
            Picker("Social Tabs", selection: $selectedTab) {
                Text("Accommodation").tag(0)
                Text("Activities").tag(1)
                Text("Social Feed").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Content
            TabView(selection: $selectedTab) {
                AccommodationView()
                    .tag(0)

                ActivitiesView()
                    .tag(1)

                SocialFeedView()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

struct AccommodationView: View {
    let accommodations = [
        Accommodation(
            id: 1,
            name: "Riad Atlas Casablanca",
            city: "Casablanca",
            type: "Traditional Riad",
            rating: 4.8,
            price: "€89/night",
            amenities: ["Free WiFi", "Parking", "Breakfast", "Pool"],
            distanceToStadium: "1.2 km from Stade Mohammed V",
            reviews: 234,
            description: "Authentic Moroccan hospitality near the stadium"
        ),
        Accommodation(
            id: 2,
            name: "Hotel Rabat Center",
            city: "Rabat",
            type: "Modern Hotel",
            rating: 4.6,
            price: "€75/night",
            amenities: ["Free WiFi", "Gym", "Restaurant", "Business Center"],
            distanceToStadium: "2.1 km from Stade Prince Moulay Abdellah",
            reviews: 189,
            description: "Contemporary comfort in the heart of the capital"
        ),
        Accommodation(
            id: 3,
            name: "Villa Salé Boutique",
            city: "Salé",
            type: "Boutique Hotel",
            rating: 4.7,
            price: "€95/night",
            amenities: ["Free WiFi", "Spa", "Garden", "Shuttle Service"],
            distanceToStadium: "0.8 km from Complexe Mohammed VI",
            reviews: 156,
            description: "Luxury stay with stadium shuttle service"
        )
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(accommodations, id: \.id) { place in
                    AccommodationCard(accommodation: place)
                }
            }
            .padding()
        }
    }
}

struct AccommodationCard: View {
    let accommodation: Accommodation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder with type badge
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "building.2")
                            .font(.title)
                            .foregroundColor(.gray)
                    )

                Text(accommodation.type)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color("moroccoGreen"))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(accommodation.name)
                            .font(.headline)
                            .lineLimit(2)
                        Text(accommodation.city)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(accommodation.price)
                            .font(.headline)
                            .foregroundColor(Color("moroccoRed"))
                            .fontWeight(.bold)

                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("\(accommodation.rating, specifier: "%.1f")")
                                .font(.caption)
                        }
                    }
                }

                // Description
                Text(accommodation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // Distance
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(accommodation.distanceToStadium)
                        .font(.caption2)
                }
                .foregroundColor(.secondary)

                // Amenities
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 2) {
                    ForEach(accommodation.amenities, id: \.self) { amenity in
                        Text(amenity)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                }

                // Footer
                HStack {
                    Text("\(accommodation.reviews) reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Book Now") {
                        // Book action
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .tint(Color("moroccoRed"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ActivitiesView: View {
    let activities = [
        Activity(
            id: 1,
            title: "Medina Food Tour",
            city: "Casablanca",
            duration: "3 hours",
            price: "€35",
            rating: 4.9,
            description: "Taste authentic Moroccan cuisine before the match",
            category: "Food & Drink"
        ),
        Activity(
            id: 2,
            title: "Hassan II Mosque Visit",
            city: "Casablanca",
            duration: "2 hours",
            price: "€15",
            rating: 4.8,
            description: "Visit one of the world's largest mosques",
            category: "Culture"
        ),
        Activity(
            id: 3,
            title: "Kasbah Walking Tour",
            city: "Rabat",
            duration: "2.5 hours",
            price: "€25",
            rating: 4.7,
            description: "Explore the historic Kasbah of the Udayas",
            category: "Culture"
        )
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(activities, id: \.id) { activity in
                    ActivityCard(activity: activity)
                }
            }
            .padding()
        }
    }
}

struct ActivityCard: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder with category badge
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "camera")
                            .font(.title)
                            .foregroundColor(.gray)
                    )

                Text(activity.category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color("moroccoGreen"))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.title)
                            .font(.headline)
                            .lineLimit(2)
                        Text(activity.city)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(activity.price)
                            .font(.headline)
                            .foregroundColor(Color("moroccoRed"))
                            .fontWeight(.bold)

                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("\(activity.rating, specifier: "%.1f")")
                                .font(.caption)
                        }
                    }
                }

                // Description
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // Duration
                Text("Duration: \(activity.duration)")
                    .font(.caption)
                    .fontWeight(.medium)

                // Book button
                Button("Book Experience") {
                    // Book action
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
                .tint(Color("moroccoRed"))
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct SocialFeedView: View {
    let socialPosts = [
        SocialPost(
            id: 1,
            user: "Ahmed_Football_Fan",
            content: "Amazing atmosphere at Stade Mohammed V tonight! Morocco played brilliantly! 🇲🇦⚽",
            likes: 127,
            comments: 23,
            shares: 12,
            time: "2 hours ago",
            hasImage: true
        ),
        SocialPost(
            id: 2,
            user: "TravelingSupporter",
            content: "Just finished the medina food tour before the match. Highly recommend the tagine at Riad Atlas! #MoroccoFootball",
            likes: 89,
            comments: 15,
            shares: 8,
            time: "4 hours ago",
            hasImage: false
        ),
        SocialPost(
            id: 3,
            user: "LocalGuide_Casa",
            content: "Perfect weather for football! If you're visiting for the match, don't miss the Hassan II Mosque tour tomorrow morning.",
            likes: 156,
            comments: 31,
            shares: 19,
            time: "6 hours ago",
            hasImage: false
        )
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(socialPosts, id: \.id) { post in
                    SocialPostCard(post: post)
                }
            }
            .padding()
        }
    }
}

struct SocialPostCard: View {
    let post: SocialPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color("moroccoRed"), Color("moroccoGreen")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.user.prefix(1)))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(post.user)
                            .fontWeight(.medium)
                        Text(post.time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Content
            Text(post.content)
                .font(.body)

            // Image placeholder if post has image
            if post.hasImage {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 180)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }

            // Interaction buttons
            HStack(spacing: 24) {
                Button(action: {
                    // Like action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.caption)
                        Text("\(post.likes)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Button(action: {
                    // Comment action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .font(.caption)
                        Text("\(post.comments)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Button(action: {
                    // Share action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                        Text("\(post.shares)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Data Models
struct Accommodation {
    let id: Int
    let name: String
    let city: String
    let type: String
    let rating: Double
    let price: String
    let amenities: [String]
    let distanceToStadium: String
    let reviews: Int
    let description: String
}

struct Activity {
    let id: Int
    let title: String
    let city: String
    let duration: String
    let price: String
    let rating: Double
    let description: String
    let category: String
}

struct SocialPost {
    let id: Int
    let user: String
    let content: String
    let likes: Int
    let comments: Int
    let shares: Int
    let time: String
    let hasImage: Bool
}

#Preview {
    SocialView()
}