# Android / Kotlin アンチパターン集

android-senior-reviewer agent が参照するリファレンス。
指摘の根拠として使用する。

---

## 🔴 Critical: 必ず指摘するアンチパターン

### AP-001: ViewModel に Context を保持する

```kotlin
// ❌ 危険: ActivityのContextをViewModelが保持するとメモリリーク
class UserViewModel : ViewModel() {
    private lateinit var context: Context

    fun init(ctx: Context) {
        context = ctx  // Activityが破棄されてもContextが解放されない
    }
}

// ✅ 正解1: ApplicationContext を使う場合は AndroidViewModel
class UserViewModel(application: Application) : AndroidViewModel(application) {
    private val appContext = application.applicationContext
}

// ✅ 正解2: UseCase/Repositoryに移譲してContextを不要にする
class UserViewModel(
    private val getUserUseCase: GetUserUseCase
) : ViewModel()
```

**リスク**: 画面回転でActivityが再生成されても、ViewModel内のContextは古いActivityを参照し続ける。GCが解放できないためメモリリーク。

---

### AP-002: GlobalScope の使用

```kotlin
// ❌ GlobalScope はアプリのライフサイクルに紐づく
// Activityが破棄されても処理が続く、キャンセルできない
GlobalScope.launch {
    repository.fetchData()
}

// ✅ viewModelScope: ViewModelが破棄されると自動キャンセル
class MyViewModel : ViewModel() {
    fun loadData() {
        viewModelScope.launch {
            repository.fetchData()
        }
    }
}

// ✅ lifecycleScope: Fragment/Activityのライフサイクルに追従
class MyFragment : Fragment() {
    fun loadData() {
        lifecycleScope.launch {
            viewModel.uiState.collect { state ->
                updateUi(state)
            }
        }
    }
}
```

---

### AP-003: Fragment で ViewBinding を解放しない

```kotlin
// ❌ onDestroyView でバインディングを null にしないと View が解放されない
class MyFragment : Fragment(R.layout.fragment_my) {
    private lateinit var binding: FragmentMyBinding
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        binding = FragmentMyBinding.bind(view)
        // onDestroyView がない → Fragment がバックスタックにある間、Viewが解放されない
    }
}

// ✅ 正解: onDestroyView で null に設定
class MyFragment : Fragment(R.layout.fragment_my) {
    private var _binding: FragmentMyBinding? = null
    private val binding get() = _binding!!
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        _binding = FragmentMyBinding.bind(view)
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null  // ← 必須
    }
}
```

---

### AP-004: Activity/Fragment にビジネスロジックを書く

```kotlin
// ❌ Activity でビジネスロジック（再試行・データ変換・バリデーション）
class LoginActivity : AppCompatActivity() {
    fun onLoginClicked() {
        val email = emailEditText.text.toString()
        if (!email.contains("@")) {
            showError("Invalid email")
            return
        }
        // APIコールのロジックがActivityに直書き
        lifecycleScope.launch {
            val result = RetrofitClient.api.login(email, password)
            if (result.isSuccessful) {
                startActivity(Intent(this@LoginActivity, HomeActivity::class.java))
            }
        }
    }
}

// ✅ ViewModel + UseCase に移譲
class LoginActivity : AppCompatActivity() {
    private val viewModel: LoginViewModel by viewModels()
    
    fun onLoginClicked() {
        viewModel.login(
            email = emailEditText.text.toString(),
            password = passwordEditText.text.toString()
        )
    }
    
    // observeのみ、UIの更新だけ
    private fun observeUiState() {
        lifecycleScope.launch {
            viewModel.uiState.collect { state ->
                when (state) {
                    is LoginUiState.Success -> navigateToHome()
                    is LoginUiState.Error -> showError(state.message)
                    is LoginUiState.Loading -> showLoading()
                }
            }
        }
    }
}
```

---

### AP-005: !! (非nullアサーション) の多用

```kotlin
// ❌ !! はKotlinのNull安全を無効化する。NullPointerExceptionが発生しうる
val user = getUser()!!
val name = user!!.name!!.trim()

// ✅ 安全な処理
val user = getUser() ?: return  // nullなら早期リターン
val name = user.name?.trim() ?: "Unknown"

// ✅ let を使った安全なnullチェック
getUser()?.let { user ->
    updateUi(user)
} ?: showEmptyState()
```

---

### AP-006: UIスレッドをブロックする

```kotlin
// ❌ runBlocking はUIスレッドをブロックし、ANRの原因になる
fun loadUserData() {
    val user = runBlocking { repository.getUser() }  // UIスレッドをブロック
    updateUi(user)
}

// ❌ Dispatchers.Main で重い処理
viewModelScope.launch(Dispatchers.Main) {
    val data = heavyComputation()  // Mainスレッドで実行
}

// ✅ 重い処理は Dispatchers.IO/Default で実行
viewModelScope.launch {
    val data = withContext(Dispatchers.IO) { repository.fetchData() }
    _uiState.value = UiState.Success(data)  // collect時にMainに戻る
}
```

---

## 🟠 Major: 重要なアンチパターン

### AP-007: LiveData/Flow を observe するときの LifecycleOwner

```kotlin
// ❌ Fragment で this を使うと、onDestroyView 後もイベントを受け取り続ける
class MyFragment : Fragment() {
    override fun onViewCreated(...) {
        viewModel.data.observe(this) { ... }  // this = Fragment本体
        // FragmentがBackStackにある間もオブザーブし続ける
    }
}

// ✅ viewLifecycleOwner を使う
class MyFragment : Fragment() {
    override fun onViewCreated(...) {
        viewModel.data.observe(viewLifecycleOwner) { ... }  // Viewのライフサイクルに追従
    }
}
```

---

### AP-008: コルーチンの例外処理漏れ

```kotlin
// ❌ launch {} 内の例外は握り潰される（ログにも出ない）
viewModelScope.launch {
    val result = repository.fetchData()  // 例外が発生しても検知できない
    _uiState.value = UiState.Success(result)
}

// ✅ try-catch で明示的にハンドリング
viewModelScope.launch {
    try {
        val result = repository.fetchData()
        _uiState.value = UiState.Success(result)
    } catch (e: IOException) {
        _uiState.value = UiState.Error(e.message ?: "Network error")
    } catch (e: Exception) {
        _uiState.value = UiState.Error("Unexpected error")
    }
}

// ✅ または CoroutineExceptionHandler を使う
val handler = CoroutineExceptionHandler { _, exception ->
    _uiState.value = UiState.Error(exception.message ?: "Error")
}
viewModelScope.launch(handler) {
    val result = repository.fetchData()
    _uiState.value = UiState.Success(result)
}
```

---

### AP-009: Compose での不要な Recomposition

```kotlin
// ❌ onClick lambda が毎回新しいインスタンスになりRecompositionを引き起こす
@Composable
fun HomeScreen(viewModel: HomeViewModel = hiltViewModel()) {
    ItemList(
        items = viewModel.items,
        onItemClick = { item -> viewModel.selectItem(item) }  // 毎回新しいlambda
    )
}

// ✅ remember でキャッシュ
@Composable
fun HomeScreen(viewModel: HomeViewModel = hiltViewModel()) {
    val onItemClick = remember(viewModel) { 
        { item: Item -> viewModel.selectItem(item) } 
    }
    ItemList(
        items = viewModel.items,
        onItemClick = onItemClick
    )
}

// ❌ StateFlow を直接 collect（ライフサイクル考慮なし）
@Composable
fun HomeScreen(viewModel: HomeViewModel = hiltViewModel()) {
    val items = remember { mutableStateListOf<Item>() }
    LaunchedEffect(Unit) {
        viewModel.items.collect { items.addAll(it) }
    }
}

// ✅ collectAsStateWithLifecycle を使う（バックグラウンド時に停止）
@Composable
fun HomeScreen(viewModel: HomeViewModel = hiltViewModel()) {
    val items by viewModel.items.collectAsStateWithLifecycle()
}
```

---

### AP-010: State Hoisting の欠如

```kotlin
// ❌ Composable内部で状態を管理（テスト不能、再利用不可）
@Composable
fun SearchBar() {
    var query by remember { mutableStateOf("") }
    TextField(
        value = query,
        onValueChange = { query = it }
    )
}

// ✅ State hoisting: 状態を呼び出し元に引き上げる
@Composable
fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit
) {
    TextField(
        value = query,
        onValueChange = onQueryChange
    )
}

// 呼び出し元でstateを管理
@Composable
fun SearchScreen() {
    var query by remember { mutableStateOf("") }
    SearchBar(
        query = query,
        onQueryChange = { query = it }
    )
}
```

---

## 🟡 Minor: Kotlin イディオム

### AP-011: var より val を優先

```kotlin
// ❌ 変更されない変数に var
var userId = "abc123"
var MAX_RETRY = 3

// ✅ 変更されないなら val / const val
val userId = "abc123"
const val MAX_RETRY = 3
```

### AP-012: if-else より when を使う

```kotlin
// ❌ 複数分岐に if-else
if (state is UiState.Loading) {
    showLoading()
} else if (state is UiState.Success) {
    showContent(state.data)
} else if (state is UiState.Error) {
    showError(state.message)
}

// ✅ when でスマートキャスト
when (state) {
    is UiState.Loading -> showLoading()
    is UiState.Success -> showContent(state.data)  // スマートキャスト
    is UiState.Error -> showError(state.message)
}
```

### AP-013: apply/also/let/run/with の使い分け

```kotlin
// apply: レシーバーを返す。オブジェクトの設定に使う
val textView = TextView(context).apply {
    text = "Hello"
    textSize = 16f
    visibility = View.VISIBLE
}

// let: null安全なブロック実行。戻り値はブロックの結果
user?.let { safeUser ->
    updateProfile(safeUser)
}

// also: サイドエフェクト（ログ、デバッグ）に使う
repository.getUser()
    .also { Log.d(TAG, "User fetched: $it") }
    .let { updateUi(it) }
```

---

## 🧪 テストパターン

### Unit Test テンプレート（ViewModel）

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class UserViewModelTest {
    
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()
    
    private val mockRepository = mockk<UserRepository>()
    private lateinit var viewModel: UserViewModel
    
    @Before
    fun setUp() {
        viewModel = UserViewModel(mockRepository)
    }
    
    @Test
    fun `ユーザー取得成功時にSuccessStateが発行される`() = runTest {
        // Given
        val expectedUser = User(id = "1", name = "Taro")
        coEvery { mockRepository.getUser("1") } returns Result.success(expectedUser)
        
        // When
        viewModel.loadUser("1")
        
        // Then
        val state = viewModel.uiState.value
        assertTrue(state is UserUiState.Success)
        assertEquals(expectedUser, (state as UserUiState.Success).user)
    }
    
    @Test
    fun `ユーザー取得失敗時にErrorStateが発行される`() = runTest {
        // Given
        coEvery { mockRepository.getUser(any()) } throws IOException("Network error")
        
        // When
        viewModel.loadUser("1")
        
        // Then
        val state = viewModel.uiState.value
        assertTrue(state is UserUiState.Error)
    }
}
```

### Compose UI Test テンプレート

```kotlin
@HiltAndroidTest
class HomeScreenTest {
    
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()
    
    @Test
    fun ユーザー一覧が表示される() {
        composeTestRule.setContent {
            HomeScreen(viewModel = hiltViewModel())
        }
        
        composeTestRule
            .onNodeWithText("Taro")
            .assertIsDisplayed()
    }
    
    @Test
    fun 検索バーに入力するとフィルタされる() {
        composeTestRule.setContent { HomeScreen() }
        
        composeTestRule
            .onNodeWithTag("SearchBar")
            .performTextInput("Taro")
        
        composeTestRule
            .onNodeWithText("Jiro")
            .assertDoesNotExist()
    }
}
```