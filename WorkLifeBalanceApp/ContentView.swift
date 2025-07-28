import SwiftUI
import Foundation

struct ContentView: View {
    @State private var age = ""
    @State private var gender = "Male"
    @State private var studyHours: Double = 1
    @State private var extracurricularHours: Double = 0.5
    @State private var sleepHours: Double = 7
    @State private var starRating = 0
    @State private var suggestionText = ""
    @State private var inputError: String? = nil
    @State private var isLoading = false
    
    let genders = ["Male", "Female", "Other"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Text("Study Cuddie")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)

                    CardView(title: "Personal Info") {
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: age) {
                                age = age.filter { $0.isNumber }
                            }
                        
                        Picker("Gender", selection: $gender) {
                            ForEach(genders, id: \.self) { Text($0) }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    CardView(title: "Your Routine (Daily)") {
                        Stepper(value: $studyHours, in: 0...12, step: 0.1) {
                            Text("Study Hours: \(studyHours, specifier: "%.1f")")
                        }
                        Stepper(value: $extracurricularHours, in: 0...12, step: 0.1) {
                            Text("Extracurriculars: \(extracurricularHours, specifier: "%.1f")")
                        }
                        Stepper(value: $sleepHours, in: 0...12, step: 0.5) {
                            Text("Sleep: \(sleepHours, specifier: "%.1f")")
                        }
                    }

                    Button(action: {
                        // Clear old messages
                        inputError = nil
                        suggestionText = ""

                        // Age validation
                        guard let ageValue = Int(age), ageValue >= 10, ageValue <= 100 else {
                            inputError = "Please enter a valid age between 10 and 100."
                            return
                        }

                        // Begin loading
                        isLoading = true

                        // Calculate rating
                        starRating = Int(calculateRating(
                            ageString: age,
                            studyHoursDaily: studyHours,
                            extracurricularHoursWeekly: extracurricularHours,
                            sleepHoursDaily: sleepHours
                        ))

                        if starRating < 5 {
                            getGeminiSuggestions()
                        } else {
                            suggestionText = "Great job! You have an excellent work-life balance."
                            isLoading = false
                        }
                    }) {
                        Text("Check Balance")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    if let error = inputError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.horizontal)
                    }

                    if isLoading {
                        ProgressView("Getting suggestions...")
                            .padding()
                    }

                    if starRating > 0 || !suggestionText.isEmpty {
                        CardView(title: "Rating") {
                            HStack {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < starRating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                }
                            }
                            .font(.title)

                            if !suggestionText.isEmpty {
                                Text(suggestionText)
                                    .padding(.top, 5)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CalendarView()) {
                        Image(systemName: "calendar")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func CardView<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 2)
            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 3)
        .padding(.horizontal)
    }

    func getGeminiSuggestions() {
        let prompt = """
        A student aged \(age), gender \(gender), studies for \(studyHours) hours, does \(extracurricularHours) hours of extracurriculars, and sleeps \(sleepHours) hours daily. Provide suggestions for improving their work-life balance.
        """
        let requestBody: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]]
        ]
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=AIzaSyBg7NG6l_Z3ryB3ouOH02MJ1IX3NR3tCMg"),
              let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                DispatchQueue.main.async {
                    self.suggestionText = text
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.suggestionText = "Sorry, we couldn't get suggestions from Gemini."
                    self.isLoading = false
                }
            }
        }.resume()
    }

    struct IdealProfile {
        let idealStudyHours: Double
        let idealSleepHours: Double
        let idealExtracurricularHours: Double
    }

    func calculateRating(ageString: String, studyHoursDaily: Double, extracurricularHoursWeekly: Double, sleepHoursDaily: Double) -> Double {
        guard let age = Double(ageString) else { return 0.0 }
        let ideal = getIdealProfile(for: age)
        let studyScore = calculateBellCurveScore(value: studyHoursDaily, ideal: ideal.idealStudyHours, width: 2.0)
        let sleepScore = calculateBellCurveScore(value: sleepHoursDaily, ideal: ideal.idealSleepHours, width: 1.5)
        let extracurricularScore = calculateBellCurveScore(value: extracurricularHoursWeekly, ideal: ideal.idealExtracurricularHours, width: 4.0)
        let totalScore = (studyScore * 0.5) + (sleepScore * 0.3) + (extracurricularScore * 0.2)
        return max(0.0, min(totalScore * 5.0, 5.0))
    }

    func getIdealProfile(for age: Double) -> IdealProfile {
        switch age {
        case 14: return IdealProfile(idealStudyHours: 1.0, idealSleepHours: 9.0, idealExtracurricularHours: 0.6875)
        case 15: return IdealProfile(idealStudyHours: 1.5, idealSleepHours: 9.0, idealExtracurricularHours: 0.6948051949)
        case 16: return IdealProfile(idealStudyHours: 2.5, idealSleepHours: 8.5, idealExtracurricularHours: 0.7067669173)
        case 17, 18: return IdealProfile(idealStudyHours: 3.5, idealSleepHours: 8.5, idealExtracurricularHours: 0.7067669173)
        default: return IdealProfile(idealStudyHours: 1.5, idealSleepHours: 9.0, idealExtracurricularHours: 5.0)
        }
    }

    func calculateBellCurveScore(value: Double, ideal: Double, width: Double) -> Double {
        let exponent = -pow(value - ideal, 2) / (2 * pow(width, 2))
        return exp(exponent)
    }
}

struct CalendarView: View {
    @State private var selectedDate = Date()

    var body: some View {
        VStack(spacing: 20) {
            Text("Select a Date")
                .font(.title2.bold())

            DatePicker("Calendar", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding()

            Text("You selected: \(selectedDate.formatted(date: .long, time: .omitted))")
                .padding()
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    ContentView()
}
