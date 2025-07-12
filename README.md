# WanderMint - AI-Powered Travel Consulting Platform

<div align="center">
  <img src="WanderMint/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png" alt="WanderMint Logo" width="120"/>
  
  [![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://developer.apple.com/ios/)
  [![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
  [![Firebase](https://img.shields.io/badge/Firebase-10.0+-yellow.svg)](https://firebase.google.com/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

## 🌍 Overview

WanderMint is a comprehensive travel consulting platform that combines a sophisticated iOS app with a powerful admin dashboard to create personalized travel experiences. The system leverages user loyalty points, preferences, and real-time data to generate detailed, custom itineraries.

### ✨ Key Features

- **📱 iOS App**: Native SwiftUI application for trip submissions and management
- **🏢 Admin Dashboard**: Web-based interface for travel consultants to create detailed itineraries
- **💳 Points Optimization**: Intelligent tracking and optimization of credit card, hotel, and airline points
- **🤖 Smart Notifications**: Automated email system for trip processing updates
- **🔍 Real-time Search**: Integration with flight search and hotel booking APIs
- **💬 Communication**: Built-in conversation system for client-consultant interaction

## 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   iOS App       │    │ Firebase Cloud  │    │ Admin Dashboard │
│   (SwiftUI)     │◄──►│   Functions     │◄──►│   (React/HTML)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         └─────────────►│   Firestore     │◄─────────────┘
                        │   Database      │
                        └─────────────────┘
                                 │
                        ┌─────────────────┐
                        │   SendGrid      │
                        │   Email Service │
                        └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Xcode 15.0+** (for iOS development)
- **Node.js 20+** (for Firebase Functions)
- **Python 3.8+** (for admin dashboard server)
- **Firebase CLI** (`npm install -g firebase-tools`)
- **CocoaPods** (`sudo gem install cocoapods`)

### 1. Clone and Setup

```bash
git clone <repository-url>
cd WanderMint

# Install iOS dependencies
pod install

# Setup Firebase Functions
cd ../travel-backend-google/functions
npm install

# Setup Admin Dashboard
cd ../../travelAdmin
npm install
```

### 2. Configuration

Create environment files:

**Admin Dashboard** (`.env` in `travelAdmin/`):
```env
FIREBASE_API_KEY=your_firebase_api_key
SERPAPI_KEY=your_serpapi_key
HOTEL_API_KEY=your_hotel_api_key
SENDGRID_API_KEY=your_sendgrid_key
```

**Firebase Functions** (set via Firebase CLI):
```bash
cd travel-backend-google/functions
firebase functions:secrets:set SENDGRID_API_KEY
```

### 3. Deploy Backend

```bash
cd travel-backend-google
firebase login
firebase deploy
```

### 4. Run Admin Dashboard

```bash
cd travelAdmin
./start-services.sh
# Access: http://localhost:8000/admin-dashboard.html
```

### 5. Build iOS App

```bash
cd WanderMint
open WanderMint.xcworkspace
# Build and run in Xcode
```

## 📱 iOS App Features

### Core Functionality
- **🔐 Authentication**: Firebase Auth with email/password
- **✈️ Trip Submission**: Enhanced form with multiple destinations
- **📋 Trip Management**: View, delete, and track trip status
- **👤 Profile Management**: User preferences and points tracking
- **💬 Conversations**: Direct communication with travel consultants

### Technical Highlights
- **SwiftUI Architecture**: Modern declarative UI framework
- **Dependency Injection**: Protocol-based service layer for testability
- **Comprehensive Testing**: 279+ unit tests with 98% code coverage
- **Content Filtering**: Advanced validation and security measures
- **Offline Support**: Graceful handling of network connectivity

### App Structure
```
WanderMint/
├── WanderMintApp.swift              # App entry point
├── Views/
│   ├── MainTabView.swift           # Tab navigation
│   ├── TripSubmissionView.swift    # Trip creation form
│   ├── TripsListView.swift         # Trip management
│   └── TripDetailView.swift        # Trip details and itinerary
├── Services/
│   ├── TripService.swift           # Trip data management
│   ├── UserService.swift           # User profile management
│   └── PointsService.swift         # Loyalty points tracking
├── Models/
│   └── DataModels.swift            # Core data structures
└── Utilities/
    ├── ContentFilter.swift         # Security and validation
    ├── FormValidation.swift        # Input validation
    └── FirebaseCompat.swift        # Firebase compatibility layer
```

## 🖥️ Admin Dashboard

### Features
- **📊 Trip Overview**: Comprehensive trip management interface
- **🗺️ Multi-Destination Planning**: Support for complex itineraries
- **🏨 Hotel Integration**: Real-time availability and booking
- **✈️ Flight Search**: Live pricing via SerpAPI integration
- **🎯 Activity Recommendations**: Curated suggestions by destination
- **💰 Cost Optimization**: Points and cash hybrid planning

### Workflow
1. **New Trip Notification**: Email alert with user points breakdown
2. **Itinerary Creation**: Use web dashboard to plan detailed trip
3. **Completion**: Mark trip complete to send itinerary to user
4. **Communication**: Handle user feedback and questions

### Dashboard Components
```
travelAdmin/
├── admin-dashboard.html            # Main dashboard interface
├── components/
│   ├── Dashboard.js               # Main dashboard logic
│   ├── TripDetailView.js          # Trip editing interface
│   ├── UserPointsDisplay.js       # Loyalty points visualization
│   └── ConversationsTab.js        # Client communication
├── hotel-proxy-server.js          # Hotel API proxy
├── serpapi-proxy-server.js        # Flight search proxy
└── start-services.sh              # Service startup script
```

## ⚡ Firebase Backend

### Cloud Functions (6 Functions Deployed)

1. **`submitTrip`**: Process new trip submissions from iOS app
2. **`processNewTrip`**: Handle new trip creation and notifications
3. **`updateTripRecommendation`**: Admin function to complete trips
4. **`onTripStatusUpdate`**: Send detailed itineraries when complete
5. **`sendConversationNotification`**: Handle user messages
6. **`onDocumentCreated`**: Conversation message triggers

### Features
- **🔒 Authentication**: Secure token verification
- **📧 Email Integration**: SendGrid for notifications
- **🛡️ Rate Limiting**: 10 trips per day per user
- **📊 Analytics**: Comprehensive logging and monitoring
- **⚡ Real-time**: Firestore triggers for instant updates

### Database Structure
```
firestore/
├── users/{userId}                  # User profiles
├── trips/{tripId}                  # Trip submissions and itineraries
├── userPoints/{userId}             # Loyalty points tracking
├── tripConversations/{convId}      # User-admin conversations
└── userSubmissions/{userId}        # Rate limiting data
```

## 🧪 Testing

### iOS App Testing
```bash
# Run all tests
xcodebuild test -scheme WanderMint -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test suite
xcodebuild test -scheme WanderMint -only-testing:WanderMintTests/TripRemovalTests
```

### Test Coverage
- **Unit Tests**: 279+ tests covering core functionality
- **Integration Tests**: End-to-end user workflows
- **Security Tests**: Content filtering and validation
- **Performance Tests**: Memory and execution time validation

### Key Test Suites
- `TripRemovalTests`: Trip deletion and validation logic
- `ContentFilterTests`: Security and content validation
- `FormValidationTests`: Input validation and sanitization
- `AuthenticationTests`: User authentication flows

## 🔐 Security

### iOS App Security
- **Content Filtering**: Advanced XSS and injection protection
- **Input Validation**: Comprehensive form validation
- **Token Management**: Secure Firebase authentication
- **Data Encryption**: HTTPS/TLS for all communications

### Backend Security
- **Firestore Rules**: User-specific data access controls
- **Admin Verification**: Email-based admin access control
- **Rate Limiting**: Protection against abuse
- **Input Sanitization**: Server-side validation

### API Security
- **Proxy Servers**: API key protection via proxy layers
- **CORS Configuration**: Proper cross-origin controls
- **Environment Variables**: Secure secret management

## 📊 Monitoring & Analytics

### Firebase Analytics
- **User Events**: Trip submissions, completions, interactions
- **Performance Metrics**: App performance and crash reporting
- **Usage Patterns**: User behavior and feature adoption

### Logging
- **Structured Logging**: JSON-formatted logs for analysis
- **Error Tracking**: Comprehensive error reporting
- **Performance Monitoring**: Response times and bottlenecks

## 🚀 Deployment

### iOS App Deployment
1. **Development**: Local testing with Firebase emulators
2. **TestFlight**: Beta testing with selected users
3. **App Store**: Production release

### Backend Deployment
```bash
# Deploy all Firebase services
cd travel-backend-google
firebase deploy

# Deploy specific services
firebase deploy --only functions
firebase deploy --only firestore:rules
```

### Admin Dashboard Deployment
```bash
cd travelAdmin
./start-services.sh
# Runs on http://localhost:8000
```

## 📈 Performance

### iOS App Performance
- **Launch Time**: < 2 seconds cold start
- **Memory Usage**: < 50MB average
- **Network Efficiency**: Minimal API calls with caching
- **Battery Impact**: Optimized background processing

### Backend Performance
- **Function Response**: < 1 second average
- **Database Queries**: Optimized with proper indexing
- **Email Delivery**: < 5 seconds for notifications
- **Concurrent Users**: Supports 1000+ simultaneous users

## 🛠️ Development Workflow

### iOS Development
1. **Feature Branch**: Create branch for new features
2. **Implementation**: Write code with comprehensive tests
3. **Testing**: Run full test suite before merging
4. **Code Review**: Peer review for quality assurance
5. **Deployment**: TestFlight for staging, App Store for production

### Backend Development
1. **Local Testing**: Firebase emulators for development
2. **Function Testing**: Unit tests for Cloud Functions
3. **Integration Testing**: End-to-end workflow validation
4. **Deployment**: Staged deployment to production

## 📚 API Documentation

### Trip Submission API
```http
POST /submitTrip
Authorization: Bearer <firebase-token>
Content-Type: application/json

{
  "destinations": ["Barcelona", "Madrid"],
  "departureLocation": "New York",
  "startDate": "2024-06-15",
  "endDate": "2024-06-25",
  "budget": "3000",
  "groupSize": 2,
  "interests": ["culture", "food"]
}
```

### Trip Update API
```http
POST /updateTripRecommendation
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "tripId": "trip123",
  "recommendation": {
    "overview": "Amazing Spain adventure",
    "itinerary": {...}
  }
}
```

## 🤝 Contributing

### Development Setup
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes with tests
4. Ensure all tests pass
5. Submit pull request

### Code Style
- **Swift**: Follow Swift API Design Guidelines
- **JavaScript**: Use ESLint configuration
- **Testing**: Maintain 95%+ test coverage
- **Documentation**: Update README for significant changes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Common Issues

**iOS Build Errors**
```bash
# Clean and rebuild
cd WanderMint
rm -rf Pods/ Podfile.lock
pod install
```

**Firebase Function Errors**
```bash
# Check function logs
firebase functions:log --limit 50

# Redeploy functions
firebase deploy --only functions
```

**Admin Dashboard Issues**
```bash
# Restart services
cd travelAdmin
./start-services.sh
```

### Getting Help
- **Issues**: Create GitHub issue for bugs
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: Check this README and inline comments
- **Email**: Contact support for urgent issues

## 🗺️ Roadmap

### Phase 1: Beta Launch ✅
- [x] iOS app with core functionality
- [x] Firebase backend with email notifications
- [x] Admin dashboard for trip processing
- [x] Comprehensive testing suite

### Phase 2: Enhanced Features 🚧
- [ ] Real-time chat between users and admins
- [ ] Advanced points optimization algorithms
- [ ] Mobile admin app for consultants
- [ ] Integration with more booking platforms

### Phase 3: Scale & Growth 📈
- [ ] Multi-language support
- [ ] Corporate travel features
- [ ] API for third-party integrations
- [ ] Advanced analytics and reporting

---

<div align="center">
  <p><strong>Ready to explore the world with WanderMint? Let's make travel planning effortless! ✈️🌟</strong></p>
</div>