//
//  HomeView.swift
//  MusicAgenda
//
//  Created by Rohan Batra on 6/16/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Top Picks for You")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.horizontal)
                
                // A horizontal scrolling section just like Apple Music
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        
                        // Card 1: Your Essentials (Purple/Pink gradient)
                        HomeCardView(
                            title: "Your\nEssentials",
                            subtitle: "Wallows, The Neighbourhood, Arctic Monkeys, Frank Ocean, and more",
                            tagline: "Made for You",
                            colors: [Color.purple, Color.indigo, Color.pink.opacity(0.8)]
                        )
                        
                        // Card 2: Replay All Time (Red/Orange/Cyan gradient)
                        HomeCardView(
                            title: "All\nTime",
                            subtitle: "Wallows, Vince Staples, Lonr., Playboi Carti, SZA, iann dior, and more",
                            tagline: "Updated Playlist",
                            header: "Replay",
                            colors: [Color.red, Color.orange, Color.cyan.opacity(0.8)]
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 40)
        }
        .navigationTitle("Home")
    }
}

// The Reusable Card Component
struct HomeCardView: View {
    let title: String
    let subtitle: String
    let tagline: String
    var header: String = ""
    let colors: [Color]
    
    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            // The Vibrant Gradient Background
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                // We add a subtle overlay to simulate Apple's fluid "mesh" look
                .overlay(
                    LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom)
                )
            
            VStack(alignment: .leading) {
                HStack {
                    if !header.isEmpty {
                        Text(header)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "applelogo")
                        .font(.title3)
                        .foregroundStyle(.white)
                    Text("Music")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Text(title)
                    // SF Pro Heavy matches the screenshot perfectly
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(.bottom, 20)
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tagline)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    Spacer()
                    
                    // The Play Button in the corner
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white, .black.opacity(0.3))
                }
            }
            .padding(24)
        }
        .frame(width: 340, height: 440)
        .cornerRadius(20)
        // Add a beautiful dynamic shadow that glows with the color of the card!
        .shadow(color: colors.last!.opacity(isHovering ? 0.6 : 0.3), radius: isHovering ? 20 : 10, y: isHovering ? 10 : 5)
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
