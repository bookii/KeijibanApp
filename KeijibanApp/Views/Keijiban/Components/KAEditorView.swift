import SwiftData
import SwiftUI

public struct KAEditorView: View {
    private enum ListType {
        case phrase
        case wordImage
    }

    private enum TextFieldType {
        case authorName
        case deleteKey
    }

    private let board: KABoard
    private let wordImagesLimit: Int = 20
    private let deleteKeyMaxLength: Int = 4
    @Environment(\.modelContext) private var modelContext
    @Environment(\.apiService) private var apiService
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedTextField: TextFieldType?
    @Binding private var isViewPresented: Bool
    @State private var wordImages: [KAWordImage]?
    @State private var phrases: [KAPhrase]?
    @State private var selectedWordImages: [KAWordImage] = []
    @State private var wordImagesCountBeforeCursor: Int = 0
    @State private var isCursorDisplayed: Bool = true
    @State private var isSheetPresented: Bool = false
    @State private var selectedListType: ListType = .phrase
    @State private var authorName: String = ""
    @State private var deleteKey: String = ""
    @State private var isCompletionAlertPresented: Bool = false
    @State private var viewHeight: CGFloat?
    @State private var error: Error?
    private var isSelectedWordImagesOver: Bool {
        selectedWordImages.count > wordImagesLimit
    }

    public init(board: KABoard, isPresented: Binding<Bool>) {
        self.board = board
        _isViewPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("\(board.name)への掲示を作成")
                .font(.kiyosuna(size: 24, weight: .bold))
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        isViewPresented = false
                    } label: {
                        Text("X")
                            .font(.stick(size: 20))
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color.black)
                            .offset(y: -2)
                    }
                }
            HStack(spacing: 16) {
                VStack(spacing: 16) {
                    selectedWordImagesView
                        .onTapGesture {
                            isSheetPresented = true
                            focusedTextField = nil
                        }
                        .frame(maxHeight: .infinity)
                    formView
                }
                .frame(maxWidth: .infinity)
                pickerView
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .ignoresSafeArea(edges: .vertical)
        .background {
            Color.kaSkyBlue
                .ignoresSafeArea()
        }
        .errorAlert($error)
        .alert("掲示を作成しました！", isPresented: $isCompletionAlertPresented) {
            Button("OK") {
                dismiss()
            }
        }
        .onAppear {
            fetchPhrasesIfNeeded()
            fetchWordImagesIfNeeded()
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
            viewHeight = height
        }
    }

    private var selectedWordImagesView: some View {
        VStack(spacing: 4) {
            ScrollView {
                KAFlowLayout(alignment: .leading, spacing: 4) {
                    if wordImagesCountBeforeCursor > 0 {
                        ForEach(selectedWordImages[0 ..< wordImagesCountBeforeCursor]) { wordImage in
                            KALazyImageView(data: wordImage.imageData)
                                .frame(height: 48)
                                .frame(maxWidth: 72)
                        }
                    }
                    if focusedTextField == nil {
                        cursorView
                    }
                    if wordImagesCountBeforeCursor < selectedWordImages.endIndex {
                        ForEach(selectedWordImages[wordImagesCountBeforeCursor ..< selectedWordImages.endIndex]) { wordImage in
                            KALazyImageView(data: wordImage.imageData)
                                .frame(height: 48)
                                .frame(maxWidth: 72)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(12)
            }
            .clipped()
            .scrollIndicators(.never)
            .scrollEdgeEffectStyle(.none, for: .all)
            .defaultScrollAnchor(.bottom, for: .sizeChanges)
            .background(in: RoundedRectangle(cornerRadius: 16))
            Text("\(selectedWordImages.count)/\(wordImagesLimit)")
                .font(.kiyosuna(size: 14))
                .foregroundStyle(Color(isSelectedWordImagesOver ? .systemRed : .secondaryLabel))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 4)
        }
    }

    private var formView: some View {
        VStack(spacing: 12) {
            Button {
                postEntry()
            } label: {
                Text("掲示する")
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedWordImages.isEmpty || isSelectedWordImagesOver)
            .frame(maxWidth: .infinity)
        }
    }

    private var cursorView: some View {
        TimelineView(.animation(minimumInterval: 0.5)) { timeline in
            let isPresented = focusedTextField == nil && Int(timeline.date.timeIntervalSince1970 * 2) % 2 == 0
            Capsule()
                .fill(Color.accentColor)
                .frame(width: 2, height: 24)
                .padding(.vertical, 12)
                .opacity(isPresented ? 1 : 0)
        }
    }

    private var pickerView: some View {
        VStack(spacing: 12) {
            Picker("", selection: $selectedListType) {
                Text("フレーズ")
                    .tag(ListType.phrase)
                Text("ワード")
                    .tag(ListType.wordImage)
            }
            .pickerStyle(.segmented)
            switch selectedListType {
            case .phrase:
                phrasesView
            case .wordImage:
                wordImagesView
            }
            HStack(spacing: 8) {
                Button {
                    if wordImagesCountBeforeCursor > 0 {
                        wordImagesCountBeforeCursor -= 1
                    }
                } label: {
                    Text("く")
                        .font(.stick(size: 16))
                        .frame(width: 16, height: 16)
                        .offset(y: -1)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                Button {
                    if wordImagesCountBeforeCursor < selectedWordImages.endIndex {
                        wordImagesCountBeforeCursor += 1
                    }
                } label: {
                    Text("く")
                        .font(.stick(size: 16))
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(180))
                        .offset(y: 2)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                Button {
                    if wordImagesCountBeforeCursor > 0 {
                        selectedWordImages.remove(at: wordImagesCountBeforeCursor - 1)
                        wordImagesCountBeforeCursor -= 1
                    }
                } label: {
                    HStack(spacing: -6) {
                        Text("く")
                            .font(.stick(size: 16))
                            .offset(y: -1)
                        Text("区")
                            .font(.stick(size: 16))
                            .rotationEffect(.degrees(180))
                            .offset(y: 1)
                    }
                    .frame(height: 16)
                    .offset(x: -1.5)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
            .foregroundStyle(Color.kaGray)
        }
    }

    private var phrasesView: some View {
        Group {
            if let phrases {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(phrases) { phrase in
                            Button {
                                selectedWordImages.append(contentsOf: phrase.wordImages)
                                wordImagesCountBeforeCursor += phrase.wordImages.count
                            } label: {
                                KAPhrasedWordImagesView(wordImages: phrase.wordImages)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .scrollIndicators(.never)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(in: RoundedRectangle(cornerRadius: 16))
        .backgroundStyle(Color(.tertiarySystemBackground))
    }

    private var wordImagesView: some View {
        Group {
            if let wordImages {
                ScrollView {
                    KAFlowLayout(alignment: .leading) {
                        ForEach(wordImages) { wordImage in
                            Button {
                                selectedWordImages.append(wordImage)
                                wordImagesCountBeforeCursor += 1
                            } label: {
                                KALazyImageView(data: wordImage.imageData)
                                    .frame(height: 48)
                                    .frame(maxWidth: 72)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .scrollIndicators(.never)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(in: RoundedRectangle(cornerRadius: 16))
        .backgroundStyle(Color(.tertiarySystemBackground))
    }

    private func fetchPhrasesIfNeeded() {
        guard phrases == nil else {
            return
        }
        let boardId = board.id
        let predicate = #Predicate<KAPhrase> { phrase in
            phrase.boards.contains(where: { $0.id == boardId })
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        do {
            phrases = try modelContext.fetch(descriptor)
        } catch {
            self.error = error
        }
    }

    private func fetchWordImagesIfNeeded() {
        guard wordImages == nil else {
            return
        }
        let boardId = board.id
        let predicate = #Predicate<KAWordImage> { $0.board.id == boardId }
        let descriptor = FetchDescriptor(predicate: predicate)
        do {
            wordImages = try modelContext.fetch(descriptor)
        } catch {
            self.error = error
        }
    }

    private func postEntry() {
        Task {
            do {
                try await apiService.postEntry(boardId: board.id, wordImages: selectedWordImages, authorName: authorName, deleteKey: deleteKey)
                isCompletionAlertPresented = true
            } catch {
                self.error = error
            }
        }
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var mockContainer: ModelContainer?
        @Previewable @State var isPresented = false
        Color(.systemGray6)
            .ignoresSafeArea()
            .overlay {
                Button("表示する") {
                    isPresented = true
                }
                .disabled(mockContainer == nil)
            }
            .fullScreenCover(isPresented: $isPresented) {
                if let mockContainer {
                    KAEditorView(board: .mockBoards().first!, isPresented: $isPresented)
                        .modelContainer(mockContainer)
                        .environment(\.apiService, KAMockApiService())
                }
            }
            .task {
                if mockContainer == nil {
                    mockContainer = await ModelContainer.mockContainer()
                }
                try? await Task.sleep(for: .seconds(1))
                isPresented = true
            }
    }
#endif
