---
name: java-spring-clean-code
description: |
  Standard di codice pulito per Java 8-21 LTS e Spring Boot 3. Applica principi Clean Code (KISS, DRY, YAGNI, SOLID), convenzioni di naming, gestione eccezioni, pattern di design e best practice Spring. Usa questo skill quando: (1) scrivi o revisioni codice Java/Spring, (2) fai refactoring per ridurre complessità, (3) crei nuove classi/metodi/test, (4) verifichi conformità SonarQube, (5) implementi architettura a layer Spring Boot. Trigger: "clean code", "refactoring", "code review", "best practice Java", "Spring Boot pattern", "ridurre complessità", "SonarQube".
---

# Java/Spring Clean Code Standards

Standard per scrivere codice Java pulito, moderno e manutenibile con Spring Boot 3.
Stack: Java 8-21 LTS + Spring Boot 3.x

## Principi Fondamentali

| Principio | Significato | Applicazione |
|-----------|-------------|--------------|
| **KISS** | Keep It Simple | Soluzioni semplici e lineari. Se serve un commento per capire, è troppo complesso |
| **DRY** | Don't Repeat Yourself | Ogni concetto una sola rappresentazione. Estrarre logica duplicata |
| **YAGNI** | You Aren't Gonna Need It | Non implementare "per il futuro". Complessità solo quando serve |
| **Boy Scout Rule** | Lascia il codice più pulito | Ogni commit migliora naming, struttura, rimuove dead code |
| **Fail Fast** | Fallire subito | Validare input all'inizio. Errori rilevati presto = debug facile |

```java
// KISS: ❌ Over-engineering
public class UserValidatorFactory {
    public static Validator<User> createValidator(ValidationType type) { /*...*/ }
}

// KISS: ✅ Semplice e diretto
public boolean isValidUser(User user) {
    return user.getEmail() != null && user.getEmail().contains("@")
        && user.getName() != null && !user.getName().isBlank();
}
```

---

## 1. Naming & Convenzioni

**Principio:** I nomi rivelano l'intento (Intention-Revealing Names).

| Elemento | Convenzione | Esempio |
|----------|-------------|---------|
| Classi/Interfacce | PascalCase | `CustomerService`, `PaymentRepository` |
| Metodi | camelCase, verbo | `calculateTotal()`, `sendEmail()` |
| Variabili | camelCase | `username`, `currentOrder` |
| Costanti | MAIUSCOLO_SNAKE | `MAX_RETRY`, `DEFAULT_TIMEOUT` |
| Package | lowercase | `com.company.project.module` |
| Spring beans | suffisso ruolo | `*Controller`, `*Service`, `*Repository` |

**Evitare:** nomi generici (`util`, `manager`, `data`), prefissi di tipo (`strName`), abbreviazioni (`usr`, `cfg`).

```java
// ❌ Naming ambiguo
double x = order.getAmount();
double y = calculate(x);

// ✅ Naming chiaro
double orderAmount = order.getAmount();
double discount = calculateDiscount(orderAmount);
```

---

## 2. Dichiarazione & Immutabilità

**Principio:** Minimizzare scope variabili, dichiarare vicino all'uso.

- `final` per variabili immutabili
- `var` (Java 10+) solo se tipo evidente dal contesto
- Costanti nominate invece di magic numbers
- Non riusare variabili per scopi diversi

```java
// ❌ Magic numbers
double b = a * 0.15;
double c = 5.99;

// ✅ Costanti nominate
private static final double DISCOUNT_RATE = 0.15;
private static final double SHIPPING_COST = 5.99;

final double basePrice = product.getPrice();
final double discount = basePrice * DISCOUNT_RATE;
final double finalPrice = basePrice - discount + SHIPPING_COST;
```

---

## 3. Struttura Classi & Metodi

**Principio:** Ogni funzione fa "una sola cosa" (SRP), <20 righe, max 3 parametri.

**Classi:**
- Coesione: ogni classe = un concetto specifico. No God class
- Campi: limitare variabili di istanza
- Incapsulamento: `private` + getter/setter, evitare `obj.getA().getB().getC()`
- Composizione > Ereditarietà

**Metodi:**
- Brevi e focalizzati (<20 righe)
- Nomi descrittivi: `sendConfirmationEmail()` non `processNotification()`
- Max 3-4 parametri, altrimenti DTO
- No flag booleani che modificano comportamento
- Guard clauses fail-fast all'inizio

```java
// ✅ Guard clause
public Customer save(Customer customer) {
    if (customer == null) throw new IllegalArgumentException("Customer is null");
    return repository.save(customer);
}
```

---

## 4. Gestione Eccezioni

**Principio:** Non usare eccezioni per flow normale. Eccezioni invece di codici errore.

```java
// ❌ Ignorare eccezioni
catch(Exception e) { /* ignoring */ }

// ✅ Log e rethrow con contesto
catch(Exception e) {
    log.error("Operation failed for user {}: {}", userId, e.getMessage());
    throw new BusinessException("Unable to complete operation", e);
}
```

**Optional vs Eccezioni vs Null:**

| Situazione | Approccio |
|------------|-----------|
| Valore potrebbe mancare (normale) | `Optional<T>` |
| Errore logico/business | Eccezione custom |
| Mai | Ritornare `null` |

```java
// ✅ Optional per assenza normale
public Optional<Customer> findByEmail(String email) {
    return Optional.ofNullable(repository.findByEmail(email));
}

// ✅ Eccezione per violazione regola business
public void withdraw(BigDecimal amount) {
    if (balance.compareTo(amount) < 0) {
        throw new InsufficientBalanceException(balance, amount);
    }
}
```

**Spring Transactions:** rollback automatico su `RuntimeException`. Non catturare nel service se vuoi rollback.

---

## 5. Commenti & Documentazione

**Principio:** Codice ben scritto documenta sé stesso. Commenti spiegano il *perché*, non il *cosa*.

**Commentare:**
```java
// Use algorithm X for performance on datasets > 10k elements
// Workaround for bug in library v2.3 - remove after upgrade
// TODO: implement retry logic - JIRA-123
```

**Non commentare:**
```java
// increment i  ← RIDONDANTE
i++;
```

**Trasformare commenti in codice:**
```java
// ❌ Commento necessario
// check if user can access the resource
if (user.getRole().equals("ADMIN") || /*...*/)

// ✅ Codice auto-documentante
if (canAccessResource(user, resource))
```

---

## 6-8. Java Features (8+, 17+, 21+)

### Java 8+
```java
// Lambda & Stream
List<String> emails = users.stream()
    .filter(this::isActiveUser)
    .map(this::normalizeEmail)
    .collect(Collectors.toList());

// Optional
String name = customer.map(Customer::getName).orElse("Anonymous");
```

### Java 17+ (LTS)
```java
// Records - ideali per DTO
public record CustomerDTO(String name, String email, LocalDate birthDate) {}

// Sealed Classes
public sealed interface Payment permits CreditCard, BankTransfer, Cash {}

// Pattern Matching instanceof
if (obj instanceof String s) {
    System.out.println(s.length());
}

// Text Blocks
String query = """
    SELECT u.id, u.name
    FROM users u
    WHERE u.active = true
    """;

// Switch Expressions
String type = switch (customer.getLevel()) {
    case 1, 2 -> "Base";
    case 3, 4 -> "Premium";
    default -> "Unknown";
};
```

### Java 21+ (LTS)
```java
// Virtual Threads - per I/O-bound tasks
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    executor.submit(() -> handleRequest(request));
}

// Sequenced Collections
list.addFirst("first");
list.getLast();
list.reversed();

// Record Patterns
if (obj instanceof Point(int x, int y)) {
    System.out.println(x + y);
}
```

---

## 9. Spring Boot 3 Essentials

### Dependency Injection via Costruttore (Best Practice)
```java
@RestController
public class CustomerController {
    private final CustomerService customerService;

    // Constructor injection - @Autowired optional
    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }
}
```
**Perché:** dipendenze esplicite, immutabili (`final`), facile da testare, fail-fast.

**Evitare field injection:** `@Autowired private Service service;`

### Architettura a Layer
```
Controller → Service → Repository
    ↓           ↓           ↓
  HTTP      Business     Data Access
```
**Regola:** non saltare layer. Controller MAI chiama Repository direttamente.

### Controller
```java
@RestController
@RequestMapping("/api/v1/users")
public class UserController {
    private final UserService userService;

    @PostMapping
    public ResponseEntity<UserDTO> create(@RequestBody @Valid CreateUserRequest request) {
        User user = userService.createUser(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(UserDTO.fromEntity(user));
    }
}
```
- Thin controllers: minima logica
- DTO per input/output, non entità JPA
- `@Valid` per validazione

### Service
```java
@Service
public class UserService {
    @Transactional
    public User createUser(CreateUserRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new UserAlreadyExistsException(request.email());
        }
        return userRepository.save(User.builder()/*...*/.build());
    }

    @Transactional(readOnly = true)
    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }
}
```
- `@Transactional` su metodi che modificano
- `@Transactional(readOnly = true)` per letture

### Global Exception Handler
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(EntityNotFoundException e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse("NOT_FOUND", e.getMessage()));
    }
}
```

---

## 10. SOLID & Design Patterns

| Principio | Descrizione | Esempio |
|-----------|-------------|---------|
| **SRP** | Una classe, una responsabilità | `OrderService` business, `OrderRepository` persistenza |
| **OCP** | Aperto estensione, chiuso modifica | Strategy pattern per sconti |
| **LSP** | Sottoclassi sostituibili | `Square` non estende `Rectangle` |
| **ISP** | Interfacce specifiche | `OnlinePayment` e `OfflinePayment` separate |
| **DIP** | Dipendere da astrazioni | Iniettare interface, non implementazione |

### Principi Avanzati

**CQS (Command Query Separation):** metodo = command (void, modifica) OPPURE query (ritorna, no modifica).

**Tell Don't Ask:** chiedere all'oggetto di fare l'operazione, non chiedere dati per operare.
```java
// ❌ Ask then Do
BigDecimal discount = order.getCustomer().getDiscountRate();
// ✅ Tell
order.applyCustomerDiscount();
```

**Step Down Rule:** ordinare metodi dall'alto (pubblici, alto livello) verso il basso (privati, dettagli).

**One Level of Abstraction:** non mescolare dettagli implementativi con logica alto livello.

---

## 11. Smells & Metriche SonarQube

| Metrica | Soglia | Cosa Misura |
|---------|--------|-------------|
| Cognitive Complexity | ≤ 15/metodo | Difficoltà comprensione flusso |
| Cyclomatic Complexity | ≤ 10/metodo | Percorsi indipendenti |
| Nesting Depth | ≤ 3 livelli | Profondità annidamento |
| Method Lines | ≤ 30 righe | Lunghezza metodo |
| Parameters | ≤ 7 | Numero parametri |
| Class Lines | ≤ 500 righe | Dimensione classe |
| Duplicated Lines | < 3% | Codice duplicato |

### Pattern per Ridurre Complessità

**Early Return:**
```java
// ❌ Nesting +3
if (order != null) { if (order.isValid()) { if (order.hasItems()) { /*...*/ }}}

// ✅ Nesting 0
if (order == null) return;
if (!order.isValid()) return;
if (!order.hasItems()) return;
// main logic
```

**Map invece di Switch:**
```java
// ❌ Cyclomatic = 5
switch (type) { case "GOLD": return 0.3; /*...*/ }

// ✅ Cyclomatic = 1
private static final Map<String, Double> DISCOUNTS = Map.of("GOLD", 0.3, /*...*/);
return DISCOUNTS.getOrDefault(type, 0.0);
```

---

## 12-13. Formattazione & Package

- Indentazione: 4 spazi
- Righe: ≤120 caratteri
- Graffe: stile K&R
- Import: no wildcard, ordinati

### Package-by-Feature
```
com.company.project/
├── order/
│   ├── OrderController.java
│   ├── OrderService.java
│   └── Order.java
├── customer/
└── common/
```

### Law of Demeter
```java
// ❌ Violation
order.getCustomer().getAddress().getCity();
// ✅ Correct
order.getShippingCity();
```

---

## 14. Testing

**Naming:** `shouldReturnCustomerWhenIdExists()`

**Struttura AAA:**
```java
@Test
void shouldCalculateTotalWithDiscount() {
    // Arrange
    var order = new Order(BigDecimal.valueOf(100));
    // Act
    BigDecimal total = order.calculateTotal(discount);
    // Assert
    assertThat(total).isEqualByComparingTo(BigDecimal.valueOf(90));
}
```

**Spring Boot Testing:**
- `@ExtendWith(MockitoExtension.class)` - unit test con mock
- `@SpringBootTest` - integration test, full context
- `@WebMvcTest` - slice test web layer
- `@DataJpaTest` - slice test repository

**Coverage:** minimo 80%, ideale >90% su business logic.

---

## 15. Lombok & JPA Best Practice

**@Data su entità JPA = PROBLEMI:**
1. `hashCode()` cambia dopo save (ID auto-generato)
2. `toString()` trigga lazy loading
3. Relazioni bidirezionali → `StackOverflowError`

**Pattern corretto:**
```java
@Entity
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
@ToString(onlyExplicitlyIncluded = true)
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class Customer {
    @Id @GeneratedValue
    @EqualsAndHashCode.Include @ToString.Include
    private Long id;

    @ToString.Include
    private String name;

    @OneToMany(mappedBy = "customer", fetch = FetchType.LAZY)
    private List<Order> orders; // Escluso da toString/equals!
}
```

| Annotazione | Su Entity JPA | Note |
|-------------|---------------|------|
| `@Getter/@Setter` | ✅ | Sicuro |
| `@NoArgsConstructor` | ✅ | Richiesto da JPA |
| `@Builder` | ✅ | Richiede @NoArgsConstructor |
| `@Data` | ❌ | **EVITARE** |
| `@ToString/@EqualsAndHashCode` | ⚠️ | Solo con `onlyExplicitlyIncluded = true` |

**Lombok OK per DTO:**
```java
@Data @Builder
public class CustomerDTO { /*...*/ }

// Meglio: Record (Java 17+)
public record CustomerDTO(Long id, String name, String email) {}
```
