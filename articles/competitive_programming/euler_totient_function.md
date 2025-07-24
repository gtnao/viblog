# オイラーのφ関数

オイラーのφ関数（Euler's totient function）は、数論において基礎的かつ重要な役割を果たす算術関数であり、競技プログラミングでは頻繁に登場する概念である。正の整数nに対して、1からnまでの整数のうちnと互いに素な整数の個数を表すこの関数は、モジュラー算術、暗号理論、組み合わせ論など幅広い分野で応用される。本稿では、オイラーのφ関数の数学的性質から始まり、効率的な計算アルゴリズム、そして競技プログラミングにおける典型的な応用例まで、体系的に解説する。

## 数学的定義と基本性質

オイラーのφ関数φ(n)は、正の整数nに対して以下のように定義される：

$$\phi(n) = |\{k : 1 \leq k \leq n, \gcd(k, n) = 1\}|$$

ここで、gcd(k, n)はkとnの最大公約数を表す。つまり、φ(n)は1からnまでの整数のうち、nと最大公約数が1である（互いに素である）整数の個数を表している。

```mermaid
graph TD
    A["φ(n): オイラーのφ関数"]
    B["入力: 正の整数n"]
    C["出力: 1からnまでの整数でnと互いに素な数の個数"]
    D["gcd(k,n) = 1となるkの個数"]
    E["例: φ(12) = 4"]
    F["1,5,7,11がgcd(k,12)=1"]
    
    A --> B
    A --> C
    C --> D
    D --> E
    E --> F
```

最初にいくつかの小さな値に対するφ関数の値を見てみよう。φ(1) = 1（1は1と互いに素）、φ(2) = 1、φ(3) = 2、φ(4) = 2、φ(5) = 4、φ(6) = 2となる。これらの値から、素数pに対してはφ(p) = p - 1となることが観察できる。これは素数の定義から明らかで、素数pは1を除くp未満のすべての正の整数と互いに素であるためである。

オイラーのφ関数は乗法的関数（multiplicative function）である。つまり、gcd(m, n) = 1ならばφ(mn) = φ(m)φ(n)が成り立つ。この性質は、素因数分解を用いたφ関数の計算において重要な役割を果たす。

## 素因数分解による計算

任意の正の整数nが素因数分解により以下のように表されるとする：

$$n = p_1^{a_1} \cdot p_2^{a_2} \cdot ... \cdot p_k^{a_k}$$

このとき、オイラーのφ関数は次の公式で計算できる：

$$\phi(n) = n \prod_{i=1}^{k} \left(1 - \frac{1}{p_i}\right) = n \prod_{i=1}^{k} \frac{p_i - 1}{p_i}$$

この公式は、φ関数の乗法性と素数べきに対する値から導出される。素数pとその正のべきkに対して、φ(p^k) = p^k - p^(k-1) = p^(k-1)(p - 1)となることを利用している。

```mermaid
graph LR
    A["n = 12 = 2² × 3"]
    B["φ(12) = 12 × (1-1/2) × (1-1/3)"]
    C["= 12 × 1/2 × 2/3"]
    D["= 4"]
    
    A --> B
    B --> C
    C --> D
```

実装においては、まずnを素因数分解し、各素因数に対して上記の公式を適用する。以下は基本的な実装例である：

```cpp
long long euler_phi(long long n) {
    long long result = n;
    for (long long p = 2; p * p <= n; p++) {
        if (n % p == 0) {
            // Remove all factors of p
            while (n % p == 0) {
                n /= p;
            }
            // Apply formula: φ(n) = n * (1 - 1/p)
            result -= result / p;
        }
    }
    // If n > 1, then it's a prime factor
    if (n > 1) {
        result -= result / n;
    }
    return result;
}
```

この実装の時間計算量はO(√n)であり、単一の値に対するφ関数の計算には十分効率的である。

## エラトステネスの篩を応用した前計算

競技プログラミングでは、複数のnに対してφ(n)を求める必要がある場合が多い。このような場合、エラトステネスの篩のアイデアを応用して、1からNまでのすべてのφ関数の値を効率的に前計算できる。

```cpp
vector<int> compute_phi_table(int N) {
    vector<int> phi(N + 1);
    // Initialize phi[i] = i
    for (int i = 0; i <= N; i++) {
        phi[i] = i;
    }
    
    // Sieve-like approach
    for (int i = 2; i <= N; i++) {
        if (phi[i] == i) {  // i is prime
            for (int j = i; j <= N; j += i) {
                phi[j] -= phi[j] / i;
            }
        }
    }
    
    return phi;
}
```

この手法の背後にある考え方は、各素数pについて、pの倍数すべてに対してφ関数の値を更新することである。素数pがnの素因数である場合、φ(n) = n × (1 - 1/p)の公式に従って値を更新する。

```mermaid
flowchart TD
    A["初期化: phi[i] = i"]
    B["i = 2 から N まで"]
    C{"phi[i] == i ?"}
    D["i は素数"]
    E["j = i, 2i, 3i, ... ≤ N"]
    F["phi[j] -= phi[j]/i"]
    G["次の i へ"]
    H["完了"]
    
    A --> B
    B --> C
    C -->|Yes| D
    C -->|No| G
    D --> E
    E --> F
    F --> G
    G --> B
    B -->|i > N| H
```

この前計算の時間計算量はO(N log log N)であり、エラトステネスの篩と同じオーダーである。空間計算量はO(N)となる。

## オイラーの定理とその応用

オイラーのφ関数は、オイラーの定理と密接に関連している。オイラーの定理は、gcd(a, n) = 1のとき、以下が成り立つことを述べている：

$$a^{\phi(n)} \equiv 1 \pmod{n}$$

この定理は、フェルマーの小定理の一般化であり、モジュラー算術において極めて重要な役割を果たす。特に、モジュラー逆元の計算や、大きなべき乗の効率的な計算に応用される。

モジュラー逆元の計算において、gcd(a, n) = 1のとき、aのmod nにおける逆元は：

$$a^{-1} \equiv a^{\phi(n)-1} \pmod{n}$$

として計算できる。これは、a × a^(φ(n)-1) ≡ a^φ(n) ≡ 1 (mod n)となることから導かれる。

```cpp
long long mod_inverse(long long a, long long n) {
    // Compute φ(n)
    long long phi = euler_phi(n);
    // Return a^(φ(n)-1) mod n
    return mod_pow(a, phi - 1, n);
}
```

## 原始根とカーマイケル関数

オイラーのφ関数は、原始根（primitive root）の理論とも深く関わっている。整数gがmod nの原始根であるとは、g^k (k = 1, 2, ..., φ(n))がmod nで互いに異なるφ(n)個の値を取ることを意味する。言い換えれば、gの位数（order）がφ(n)に等しいということである。

原始根が存在するための必要十分条件は、nが1, 2, 4, p^k, 2p^k（ただしpは奇素数）のいずれかの形であることである。原始根の個数は、存在する場合φ(φ(n))個となる。

カーマイケル関数λ(n)は、オイラーのφ関数の改良版とも言える関数で、すべてのgcd(a, n) = 1なるaに対してa^λ(n) ≡ 1 (mod n)となる最小の正の整数λ(n)を与える。カーマイケル関数は以下のように定義される：

- λ(1) = 1
- λ(2) = 1, λ(4) = 2, λ(2^k) = 2^(k-2) (k ≥ 3)
- λ(p^k) = φ(p^k) = p^(k-1)(p-1) （pは奇素数）
- λ(mn) = lcm(λ(m), λ(n)) （gcd(m,n) = 1）

## 競技プログラミングにおける典型問題

オイラーのφ関数は、競技プログラミングにおいて様々な形で出題される。以下、典型的な問題パターンを見ていく。

### 1. 直接的なφ関数の計算

最も基本的なパターンは、与えられたnに対してφ(n)を求める問題である。前述の素因数分解による方法で解くことができる。

### 2. φ関数の総和

Σ_{i=1}^n φ(i)を求める問題は、数論的な考察を要する興味深い問題である。この和は、1からnまでの既約分数の個数と関連している。具体的には、分母がn以下の既約分数（0と1の間）の個数は、Σ_{i=1}^n φ(i) - 1となる。

```cpp
long long phi_sum(int n) {
    vector<int> phi = compute_phi_table(n);
    long long sum = 0;
    for (int i = 1; i <= n; i++) {
        sum += phi[i];
    }
    return sum;
}
```

### 3. べき乗の周期性

a^k mod nの値は、kが大きくなると周期的になる。この周期はφ(n)の約数であることが、オイラーの定理から保証される。特に、gcd(a, n) = 1の場合、周期はaのmod nにおける位数と呼ばれ、φ(n)の約数となる。

```mermaid
graph TD
    A["a^k mod n の周期"]
    B["gcd(a,n) = 1 の場合"]
    C["周期 d は φ(n) の約数"]
    D["a^d ≡ 1 (mod n)"]
    E["最小の d が位数"]
    
    A --> B
    B --> C
    C --> D
    D --> E
```

### 4. 反復べき乗

a^(a^(a^(...))) mod nのような反復べき乗の値を求める問題では、オイラーの定理を利用して指数部分を簡約化する。具体的には、以下の性質を利用する：

$$a^x \equiv a^{x \bmod \phi(n) + \phi(n)} \pmod{n} \quad (x \geq \log_2 n)$$

```cpp
long long tower_mod(vector<long long>& a, int idx, long long mod) {
    if (mod == 1) return 0;
    if (idx == a.size() - 1) return a[idx] % mod;
    
    long long phi = euler_phi(mod);
    long long exp = tower_mod(a, idx + 1, phi);
    
    // Check if exp >= log2(mod)
    if (exp >= 64 || (1LL << exp) >= mod) {
        exp = exp % phi + phi;
    }
    
    return mod_pow(a[idx], exp, mod);
}
```

## 数え上げ問題への応用

オイラーのφ関数は、様々な数え上げ問題にも応用される。例えば、円環上にn個の異なる色のビーズを配置する方法の数を求める問題（ネックレス問題）では、バーンサイドの補題と組み合わせてφ関数が使用される。

n個のビーズを円環上に配置する際、回転によって同じになる配置を同一視する場合、異なる配置の数は：

$$\frac{1}{n} \sum_{d|n} \phi(d) \cdot f(n/d)$$

ここで、f(k)はk個の周期で繰り返すパターンの数を表す。

## RSA暗号との関連

オイラーのφ関数は、現代暗号の基礎であるRSA暗号においても中心的な役割を果たす。RSA暗号では、2つの大きな素数p, qの積n = pqを法とし、φ(n) = (p-1)(q-1)を利用して暗号化・復号化を行う。

公開鍵eと秘密鍵dは、ed ≡ 1 (mod φ(n))を満たすように選ばれる。これにより、メッセージmに対して：

$$(m^e)^d \equiv m^{ed} \equiv m \pmod{n}$$

となり、暗号化と復号化が実現される。RSAの安全性は、nの素因数分解の困難性に依存しており、nからφ(n)を効率的に計算することの困難性とも関連している。

## 実装上の注意点とテクニック

競技プログラミングにおいてオイラーのφ関数を扱う際には、いくつかの実装上の注意点がある。

まず、オーバーフローに注意が必要である。φ(n)の計算過程で、一時的にnより大きな値を扱う可能性があるため、適切な型の選択と、必要に応じたモジュラー演算の適用が重要である。

```cpp
// Overflow-safe implementation
long long safe_euler_phi(long long n, long long mod) {
    long long result = n % mod;
    for (long long p = 2; p * p <= n; p++) {
        if (n % p == 0) {
            while (n % p == 0) n /= p;
            result = result / p * (p - 1) % mod;
        }
    }
    if (n > 1) {
        result = result / n * (n - 1) % mod;
    }
    return result;
}
```

また、複数のクエリに対応する場合は、前計算とメモ化を組み合わせることで効率化できる。特に、同じnに対して繰り返しφ(n)を計算する可能性がある場合は、結果をキャッシュすることで大幅な高速化が可能である。

## 一般化と拡張

オイラーのφ関数の概念は、より一般的な設定に拡張できる。例えば、多項式環における類似の概念や、有限体上での応用などがある。また、ヨルダンのトーシェント関数J_k(n)は、φ関数の一般化であり、k-タプル(a_1, ..., a_k)でgcd(a_1, ..., a_k, n) = 1となるものの個数を表す。特に、J_1(n) = φ(n)である。

デデキントのψ関数も関連する概念で、ψ(n) = n × Π_{p|n}(1 + 1/p)として定義される。この関数は、nの約数の逆数の和と関連している。

## 計算複雑性の観点から

オイラーのφ関数の計算複雑性は、素因数分解の複雑性と密接に関連している。現在知られている最も効率的な素因数分解アルゴリズムは準指数時間で動作するため、任意の大きな合成数に対してφ関数を効率的に計算することは困難である。

一方で、特殊な形の数に対しては効率的な計算が可能である。例えば、素数p、素数べきp^k、または既知の素因数分解を持つ数に対しては、φ関数は定数時間または線形時間で計算できる。

競技プログラミングの文脈では、通常扱う数の範囲が限定されているため、O(√n)の素因数分解アルゴリズムで十分な場合が多い。しかし、問題によってはより効率的なアプローチが必要となることもある。

## デバッグとテストのアプローチ

オイラーのφ関数の実装をデバッグする際には、以下の性質を利用してテストケースを作成すると効果的である：

1. φ(1) = 1
2. 素数pに対してφ(p) = p - 1
3. φ(2n) = φ(n) （nが奇数の場合）
4. φ(2n) = 2φ(n) （nが偶数の場合）
5. Σ_{d|n} φ(d) = n

特に最後の性質は、実装の正確性を検証する際に有用である。nの約数すべてに対するφ関数の値の和がnに等しくなることを確認することで、実装の妥当性をチェックできる。

```cpp
bool verify_phi_implementation(int n) {
    vector<int> divisors;
    for (int i = 1; i * i <= n; i++) {
        if (n % i == 0) {
            divisors.push_back(i);
            if (i != n / i) divisors.push_back(n / i);
        }
    }
    
    int sum = 0;
    for (int d : divisors) {
        sum += euler_phi(d);
    }
    
    return sum == n;
}
```

## 高度な最適化手法

競技プログラミングの実践において、基本的なアルゴリズムだけでは時間制限に間に合わない場合がある。そのような状況では、より高度な最適化手法が必要となる。

### ポラード・ロー法による素因数分解

大きな数に対してφ関数を計算する必要がある場合、通常のO(√n)の素因数分解では時間がかかりすぎることがある。ポラード・ロー法は、確率的アルゴリズムであるが、平均的にO(n^(1/4))の時間計算量で素因数を見つけることができる。

```cpp
long long pollard_rho(long long n) {
    if (n % 2 == 0) return 2;
    if (is_prime(n)) return n;
    
    auto f = [&](long long x) {
        return (__int128)x * x % n + 1;
    };
    
    long long x = 2, y = 2, d = 1;
    while (d == 1) {
        x = f(x);
        y = f(f(y));
        d = gcd(abs(x - y), n);
    }
    
    return d == n ? pollard_rho(n) : d;
}
```

この手法を用いることで、10^18程度の大きな数に対してもφ関数を実用的な時間で計算できる。

### メビウス関数との関係

メビウス関数μ(n)とオイラーのφ関数には深い関係がある。メビウス関数は以下のように定義される：

- μ(n) = 1 （nが偶数個の異なる素因数の積）
- μ(n) = -1 （nが奇数個の異なる素因数の積）
- μ(n) = 0 （nが平方因子を持つ）

この関数を用いると、φ関数は以下の式で表現できる：

$$\phi(n) = \sum_{d|n} \mu(d) \cdot \frac{n}{d}$$

この関係は、包除原理を用いた別の観点からφ関数を理解する手段を提供する。

```mermaid
graph TD
    A["メビウス関数 μ(n)"]
    B["n = p₁ × p₂ × ... × pₖ"]
    C["μ(n) = (-1)^k"]
    D["平方因子あり"]
    E["μ(n) = 0"]
    F["φ(n) = Σ μ(d) × n/d"]
    
    A --> B
    B --> C
    A --> D
    D --> E
    A --> F
```

## 離散対数問題への応用

オイラーのφ関数は、離散対数問題の解法においても重要な役割を果たす。離散対数問題とは、g^x ≡ h (mod p)を満たすxを求める問題である。

### Baby-step Giant-step アルゴリズム

このアルゴリズムは、O(√φ(p))の時間計算量で離散対数を計算する。φ(p)の値を知ることで、探索範囲を効率的に制限できる。

```cpp
long long discrete_log(long long g, long long h, long long p) {
    long long phi = euler_phi(p);
    long long m = ceil(sqrt(phi));
    
    unordered_map<long long, long long> table;
    long long g_pow = 1;
    
    // Baby steps
    for (long long j = 0; j < m; j++) {
        table[g_pow] = j;
        g_pow = g_pow * g % p;
    }
    
    // Giant steps
    long long g_inv_m = mod_pow(mod_inverse(g, p), m, p);
    long long gamma = h;
    
    for (long long i = 0; i < m; i++) {
        if (table.count(gamma)) {
            return i * m + table[gamma];
        }
        gamma = gamma * g_inv_m % p;
    }
    
    return -1;  // No solution
}
```

## 中国剰余定理との組み合わせ

中国剰余定理（Chinese Remainder Theorem, CRT）とオイラーのφ関数を組み合わせることで、より効率的な計算が可能になる場合がある。

n = p₁^a₁ × p₂^a₂ × ... × pₖ^aₖと素因数分解されるとき、各素数べきに対してφ(pᵢ^aᵢ)を計算し、それらを乗法的に組み合わせることで全体のφ(n)を得る。これは、大きな数を扱う際に数値的な安定性を保つ上でも有効である。

```cpp
struct CRT {
    vector<long long> m, r;
    
    void add_congruence(long long mi, long long ri) {
        m.push_back(mi);
        r.push_back(ri);
    }
    
    pair<long long, long long> solve() {
        long long M = 1, R = 0;
        for (int i = 0; i < m.size(); i++) {
            long long Mi = M / gcd(M, m[i]) * m[i];
            long long g, x, y;
            extended_gcd(M, m[i], g, x, y);
            if ((r[i] - R) % g != 0) return {-1, -1};
            
            long long t = (r[i] - R) / g * x % (m[i] / g);
            R += M * t;
            M = Mi;
        }
        return {R % M, M};
    }
};
```

## 実装の並列化

現代のマルチコアプロセッサを活用して、φ関数の計算を並列化することも可能である。特に、前計算テーブルの構築や、複数の独立したクエリの処理において効果的である。

```cpp
#include <thread>
#include <future>

vector<int> parallel_phi_table(int N, int num_threads = 4) {
    vector<int> phi(N + 1);
    vector<future<void>> futures;
    
    int chunk_size = (N + num_threads - 1) / num_threads;
    
    for (int t = 0; t < num_threads; t++) {
        futures.push_back(async(launch::async, [&, t]() {
            int start = t * chunk_size;
            int end = min((t + 1) * chunk_size, N + 1);
            
            for (int i = start; i < end; i++) {
                phi[i] = euler_phi(i);
            }
        }));
    }
    
    for (auto& f : futures) {
        f.wait();
    }
    
    return phi;
}
```

## セグメント木による区間クエリ

競技プログラミングでは、配列の区間に対するφ関数の和や積を求める問題も出題される。このような場合、セグメント木を用いることで効率的にクエリを処理できる。

```cpp
template<typename T>
class SegmentTree {
    vector<T> tree;
    int n;
    
    void build(vector<T>& arr, int node, int start, int end) {
        if (start == end) {
            tree[node] = euler_phi(arr[start]);
        } else {
            int mid = (start + end) / 2;
            build(arr, 2*node, start, mid);
            build(arr, 2*node+1, mid+1, end);
            tree[node] = tree[2*node] + tree[2*node+1];
        }
    }
    
public:
    SegmentTree(vector<T>& arr) {
        n = arr.size();
        tree.resize(4 * n);
        build(arr, 1, 0, n-1);
    }
    
    T query(int l, int r) {
        return query_rec(1, 0, n-1, l, r);
    }
    
private:
    T query_rec(int node, int start, int end, int l, int r) {
        if (r < start || end < l) return 0;
        if (l <= start && end <= r) return tree[node];
        
        int mid = (start + end) / 2;
        return query_rec(2*node, start, mid, l, r) +
               query_rec(2*node+1, mid+1, end, l, r);
    }
};
```

## 数論的変換での応用

数論的変換（Number Theoretic Transform, NTT）は、高速フーリエ変換の整数版であり、モジュラー算術を用いて多項式の積を効率的に計算する。NTTでは、法となる素数pがp = k × 2^n + 1の形である必要があり、原始根の計算にφ関数が使用される。

```cpp
const long long NTT_PRIME = 998244353;  // = 119 * 2^23 + 1

long long find_primitive_root(long long p) {
    long long phi = p - 1;  // p is prime
    vector<long long> factors;
    
    // Find prime factors of φ(p)
    long long temp = phi;
    for (long long i = 2; i * i <= temp; i++) {
        if (temp % i == 0) {
            factors.push_back(i);
            while (temp % i == 0) temp /= i;
        }
    }
    if (temp > 1) factors.push_back(temp);
    
    // Check each candidate
    for (long long g = 2; g < p; g++) {
        bool is_primitive = true;
        for (long long factor : factors) {
            if (mod_pow(g, phi / factor, p) == 1) {
                is_primitive = false;
                break;
            }
        }
        if (is_primitive) return g;
    }
    
    return -1;  // Should not reach here for valid prime
}
```

## 誤差評価と数値的安定性

大きな数に対してφ関数を計算する際、浮動小数点演算を使用すると誤差が蓄積する可能性がある。特に、φ(n) = n × Π(1 - 1/p)の公式を直接適用する場合は注意が必要である。

整数演算を保つためには、以下のような実装が推奨される：

```cpp
long long stable_euler_phi(long long n) {
    long long result = n;
    vector<pair<long long, int>> factors = factorize(n);
    
    for (auto [p, exp] : factors) {
        // Avoid floating point: result *= (p-1)/p
        result = result / p * (p - 1);
    }
    
    return result;
}
```

## 問題例と解法パターン

### パターン1: 条件を満たすφ(n)の個数

「φ(n) = kとなるnの個数を求めよ」という形式の問題は、φ関数の逆関数を考える必要がある。一般に、φ(n) = kとなるnは有限個存在し、それらは特定の形に限定される。

```cpp
vector<long long> inverse_phi(long long k) {
    vector<long long> result;
    
    // n = 1, 2 are special cases
    if (k == 1) {
        result.push_back(1);
        result.push_back(2);
    }
    
    // For k > 1, check divisors of k
    for (long long d = 1; d * d <= k; d++) {
        if (k % d == 0) {
            check_candidate(k, d, result);
            if (d != k / d) {
                check_candidate(k, k / d, result);
            }
        }
    }
    
    return result;
}
```

### パターン2: φ関数の反復適用

「φ(φ(...φ(n)...))を計算せよ」という形式の問題では、φ関数を繰り返し適用すると最終的に1に収束することを利用する。

```cpp
long long iterated_phi(long long n, long long k) {
    for (long long i = 0; i < k && n > 1; i++) {
        n = euler_phi(n);
    }
    return n;
}
```

オイラーのφ関数は、その単純な定義にもかかわらず、数論の深い性質と密接に関わっており、競技プログラミングにおいても多様な応用を持つ。基本的な計算方法から始まり、効率的なアルゴリズム、そして様々な問題への応用まで、体系的に理解することで、より複雑な問題にも対処できるようになる。特に、モジュラー算術、数え上げ問題、暗号理論などの分野では、φ関数の理解が問題解決の鍵となることが多い。高度な最適化手法や並列化技術を組み合わせることで、実用的な時間内により大きな問題インスタンスを解くことも可能となる。

---

[^1]: Euler, L. (1763). "Theoremata arithmetica nova methodo demonstrata". Novi Commentarii academiae scientiarum Petropolitanae 8, pp. 74-104.

[^2]: Hardy, G. H., & Wright, E. M. (2008). An Introduction to the Theory of Numbers (6th ed.). Oxford University Press.

[^3]: Knuth, D. E. (1997). The Art of Computer Programming, Volume 2: Seminumerical Algorithms (3rd ed.). Addison-Wesley.

[^4]: Bach, E., & Shallit, J. (1996). Algorithmic Number Theory, Volume 1: Efficient Algorithms. MIT Press.

[^5]: Rosen, K. H. (2011). Elementary Number Theory and Its Applications (6th ed.). Pearson.