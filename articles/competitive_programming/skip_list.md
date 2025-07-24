# スキップリスト

スキップリストは、1990年にWilliam Pughによって考案された確率的データ構造である[^1]。この構造は、ソート済みのデータに対して期待計算量O(log n)での検索、挿入、削除を実現する。従来の平衡木（AVL木や赤黒木など）と同等の性能を持ちながら、実装が著しく単純であることが最大の特徴といえる。平衡木が複雑な回転操作や色の管理を必要とするのに対し、スキップリストは確率的な手法によって期待的にバランスを保つため、実装の複雑さが大幅に軽減される。

```mermaid
graph TD
    subgraph "Level 3"
        H3["HEAD"] --> 30L3["30"] --> T3["TAIL"]
    end
    
    subgraph "Level 2"
        H2["HEAD"] --> 10L2["10"] --> 30L2["30"] --> T2["TAIL"]
    end
    
    subgraph "Level 1"
        H1["HEAD"] --> 10L1["10"] --> 20L1["20"] --> 30L1["30"] --> 50L1["50"] --> T1["TAIL"]
    end
    
    subgraph "Level 0"
        H0["HEAD"] --> 10L0["10"] --> 20L0["20"] --> 30L0["30"] --> 40L0["40"] --> 50L0["50"] --> 60L0["60"] --> T0["TAIL"]
    end
    
    30L3 -.-> 30L2
    10L2 -.-> 10L1
    30L2 -.-> 30L1
    10L1 -.-> 10L0
    20L1 -.-> 20L0
    30L1 -.-> 30L0
    50L1 -.-> 50L0
```

スキップリストの基本的な着想は、通常の連結リストに「エクスプレスレーン」を追加することにある。最下層（レベル0）には全ての要素が存在し、上位レベルになるほど要素数が減少していく。各要素は確率的に上位レベルに昇格し、これによって長距離を高速に移動できる経路が形成される。検索時には最上位レベルから開始し、目的の要素に近づくにつれて下位レベルに降りていくことで、効率的な探索が可能となる。

## データ構造の詳細

スキップリストの各ノードは、保持する値とレベル数、そして各レベルにおける次のノードへのポインタ配列を持つ。レベルは0から始まり、レベルiのノードはレベル0からレベルiまでの全てのレベルに存在する。各レベルは独立したソート済み連結リストを形成し、上位レベルは下位レベルの部分集合となる。

```mermaid
classDiagram
    class Node {
        -int value
        -int level
        -Node[] forward
        +Node(value, level)
        +getValue()
        +getLevel()
        +getForward(level)
        +setForward(level, node)
    }
    
    class SkipList {
        -Node head
        -int maxLevel
        -float probability
        -Random random
        +search(value)
        +insert(value)
        +delete(value)
        -randomLevel()
    }
    
    SkipList --> Node : contains
```

ノードのレベル決定は確率的に行われる。一般的には確率p（通常0.5または0.25）を用いて、レベルiのノードがレベルi+1にも存在する確率をpとする。この確率分布により、レベルkに存在するノード数の期待値はn×p^kとなる。pが0.5の場合、各レベルのノード数は期待的に半分ずつ減少していく。

レベル決定アルゴリズムは幾何分布に従う。具体的には、コインを投げて表が出続ける限りレベルを増やし、裏が出た時点でそのレベルに決定する。これにより、レベルkが選ばれる確率は(1-p)×p^kとなる。最大レベルは通常log_{1/p}(n)に制限され、メモリ使用量の上限を保証する。

## 検索アルゴリズム

スキップリストの検索は、最上位レベルから開始して段階的に下位レベルに降りていく過程として実装される。各レベルでは、検索対象より大きい値に到達するまで前進し、そこで一つ下のレベルに移動する。この動作を最下層まで繰り返すことで、目的の要素またはその直前の要素に到達する。

```mermaid
flowchart TD
    Start["開始: 最上位レベルから"] --> CheckCurrent{"現在のノードの<br/>次の値 ≤ 検索値?"}
    CheckCurrent -->|Yes| MoveForward["同じレベルで前進"]
    MoveForward --> CheckCurrent
    CheckCurrent -->|No| CheckLevel{"最下層?"}
    CheckLevel -->|No| MoveDown["一つ下のレベルへ"]
    MoveDown --> CheckCurrent
    CheckLevel -->|Yes| CheckFound{"次の値 = 検索値?"}
    CheckFound -->|Yes| Found["発見"]
    CheckFound -->|No| NotFound["存在しない"]
```

検索の計算量解析において重要なのは、各レベルで前進するステップ数の期待値である。確率pでノードが上位レベルに存在する場合、レベルiで前進する期待ステップ数は1/pとなる。全体のレベル数が期待的にlog_{1/p}(n)であることから、検索の期待計算量はO(log n)となる。

検索経路の記録は、後続の挿入・削除操作において重要な役割を果たす。各レベルで下降する直前のノードを配列に保存することで、新しいノードの挿入位置や削除時の接続更新を効率的に行うことができる。この更新配列は、検索操作の副産物として自然に得られる。

## 挿入アルゴリズム

挿入操作は、まず通常の検索を実行して挿入位置を特定することから始まる。検索過程で各レベルの更新位置を記録し、新しいノードのレベルを確率的に決定する。その後、決定されたレベル以下の全てのレベルにおいて、記録された更新位置から新しいノードへのリンクを張り替える。

```mermaid
sequenceDiagram
    participant Client
    participant SkipList
    participant RandomGenerator
    participant Node
    
    Client->>SkipList: insert(value)
    SkipList->>SkipList: search and record update positions
    SkipList->>RandomGenerator: randomLevel()
    RandomGenerator-->>SkipList: level
    SkipList->>Node: new Node(value, level)
    loop for each level i from 0 to level
        SkipList->>SkipList: update[i].forward[i] = newNode
        SkipList->>SkipList: newNode.forward[i] = old forward
    end
    SkipList-->>Client: success
```

新しいノードのレベルが現在の最大レベルを超える場合、スキップリストの高さを拡張する必要がある。この際、新しく追加されたレベルのヘッドノードから新しいノードへの直接リンクが設定される。最大レベルの管理は、スキップリスト全体の構造を保つ上で重要な要素となる。

挿入操作の期待計算量もO(log n)である。これは、検索にO(log n)、レベル決定にO(1)、リンクの更新に期待的にO(log n)の時間がかかることによる。リンク更新の計算量が対数的である理由は、新しいノードのレベルが期待的にO(log n)に制限されるためである。

## 削除アルゴリズム

削除操作は挿入操作と対称的な構造を持つ。まず削除対象のノードを検索し、各レベルでの更新位置を記録する。対象ノードが見つかった場合、そのノードが存在する全てのレベルにおいてリンクを更新し、前のノードを次のノードに直接接続する。

削除後の処理として、最上位レベルが空になった場合はスキップリストの高さを減少させる。これにより、不要なレベルの走査を避け、性能を維持することができる。ただし、高さの減少は必須ではなく、実装によっては省略されることもある。

## 確率的解析と性能保証

スキップリストの性能は確率的に保証される。n個の要素を持つスキップリストにおいて、高さがc×log_{1/p}(n)を超える確率は1/n^{c-1}となる。これは、極めて高い確率で対数的な高さが維持されることを意味する。

```mermaid
graph LR
    subgraph "確率分布"
        A["レベル0: 100%"] --> B["レベル1: 50%"]
        B --> C["レベル2: 25%"]
        C --> D["レベル3: 12.5%"]
        D --> E["..."]
    end
    
    subgraph "期待ノード数"
        F["n個"] --> G["n/2個"]
        G --> H["n/4個"]
        H --> I["n/8個"]
        I --> J["..."]
    end
```

空間計算量の期待値は、各ノードが期待的に1/(1-p)個のポインタを持つことから、O(n)となる。p=0.5の場合、各ノードは平均2個のポインタを持つ。これは平衡木の各ノードが持つポインタ数と同程度であり、空間効率の面でも競争力がある。

最悪計算量については、理論的にはO(n)となる可能性がある。これは、全てのノードが最大レベルを持つような極端なケースで発生する。しかし、このような状況が発生する確率は極めて低く、実用上は問題にならない。確率pを適切に選択することで、最悪ケースの発生確率を任意に小さくできる。

## 実装の詳細と最適化

実用的なスキップリストの実装では、いくつかの最適化技法が適用される。まず、センチネルノードの使用により境界条件の処理が簡略化される。ヘッドノードには最小値（通常は負の無限大）、テールノードには最大値（正の無限大）を設定することで、特殊ケースの処理を排除できる。

```cpp
template<typename T>
class SkipList {
private:
    struct Node {
        T value;
        std::vector<Node*> forward;
        
        Node(const T& val, int level) 
            : value(val), forward(level + 1, nullptr) {}
    };
    
    Node* head;
    int maxLevel;
    float probability;
    std::mt19937 generator;
    std::bernoulli_distribution distribution;
    
    int randomLevel() {
        int level = 0;
        while (distribution(generator) && level < maxLevel) {
            level++;
        }
        return level;
    }
    
public:
    SkipList(int maxLvl = 16, float p = 0.5) 
        : maxLevel(maxLvl), probability(p), 
          generator(std::random_device{}()), 
          distribution(p) {
        head = new Node(T{}, maxLevel);
    }
};
```

メモリアクセスパターンの最適化も重要な考慮事項である。スキップリストは本質的にポインタベースの構造であるため、キャッシュ性能が課題となる可能性がある。これを改善するため、小さなノードではポインタ配列を固定サイズにし、メモリアロケーションの回数を減らす実装が存在する。

並行性の観点から、スキップリストは優れた特性を持つ。読み取り操作は本質的にロックフリーで実装可能であり、書き込み操作も細粒度のロックで効率的に実装できる。各ノードのレベルごとにロックを取得することで、異なるレベルでの操作を並行して実行できる。

## 他のデータ構造との比較

平衡二分探索木（AVL木、赤黒木）と比較すると、スキップリストは実装の単純さにおいて明確な優位性を持つ。回転操作や色の管理が不要であり、バグの混入リスクが低い。性能面では理論的に同等のO(log n)を達成するが、定数項では若干劣る場合がある。

B木やB+木との比較では、スキップリストは外部記憶向けではないという違いがある。B木系のデータ構造はディスクアクセスを最小化するよう設計されているのに対し、スキップリストは主にメモリ上での使用を想定している。ただし、各レベルを別々のファイルとして管理することで、外部記憶向けの変種も提案されている。

ハッシュテーブルとの比較では、順序付けの有無が決定的な違いとなる。スキップリストは順序付きの操作（範囲検索、最小値・最大値の取得など）を効率的にサポートするが、ハッシュテーブルは順序を保持しない。一方、単純な検索・挿入・削除の期待計算量では、ハッシュテーブルのO(1)に対してスキップリストはO(log n)となる。

## 実践的な応用と変種

スキップリストは、その単純さと効率性から様々なシステムで採用されている。Redisのソート済みセット（ZSET）の実装[^2]、LevelDBやRocksDBでのMemTableの実装[^3]、Apache Luceneでの転置インデックスの実装など、実用的なシステムでの採用例は多い。

決定的スキップリストは、確率的な要素を排除した変種である。レベルの決定を値のハッシュ値などから決定的に行うことで、再現性のある動作を保証する。これは、分散システムでのレプリケーションやデバッグが容易になるという利点がある。

インデックス可能スキップリストは、各ノードがサブツリーのサイズ情報を保持することで、順序統計量（k番目の要素）へのアクセスをO(log n)で実現する。この拡張により、ランダムアクセスが必要なアプリケーションでも効率的に使用できる。

## 実装上の注意点とベストプラクティス

確率パラメータpの選択は、性能とメモリ使用量のトレードオフを決定する重要な要素である。p=0.5は最も一般的な選択であり、理論と実践のバランスが良い。p=0.25を使用すると、メモリ使用量は削減されるが、走査するノード数が増加する。実際のアプリケーションでは、データサイズとアクセスパターンに基づいて適切な値を選択する必要がある。

最大レベルの設定も重要である。理論的にはlog_{1/p}(n)で十分だが、nが事前に分からない場合は十分大きな値（32や64）を設定することが一般的である。ただし、過度に大きな値は無駄なメモリアロケーションにつながるため、適切なバランスが必要となる。

エラー処理とメモリ管理については、特に注意が必要である。ノードの削除時にはメモリリークを防ぐため、適切にメモリを解放する必要がある。また、挿入時のメモリアロケーション失敗に対する処理も実装する必要がある。C++では、スマートポインタを使用することでこれらの問題を軽減できる。

[^1]: Pugh, William (1990). "Skip Lists: A Probabilistic Alternative to Balanced Trees". Communications of the ACM. 33 (6): 668–676.

[^2]: Redis Documentation. "Redis Sorted Sets". https://redis.io/docs/data-types/sorted-sets/

[^3]: LevelDB Documentation. "Implementation Details". https://github.com/google/leveldb/blob/master/doc/impl.md

## 範囲検索と順序統計

スキップリストの重要な利点の一つは、効率的な範囲検索をサポートすることである。開始値から終了値までの全ての要素を順序通りに取得する操作は、最初の要素を見つけた後、最下層のリンクを辿ることで実現される。この操作の計算量はO(log n + k)となる。ここでkは範囲内の要素数である。

```cpp
template<typename T>
std::vector<T> SkipList<T>::range(const T& start, const T& end) {
    std::vector<T> result;
    Node* current = head;
    
    // Find the first element >= start
    for (int i = currentLevel; i >= 0; i--) {
        while (current->forward[i] && current->forward[i]->value < start) {
            current = current->forward[i];
        }
    }
    
    current = current->forward[0];
    
    // Collect all elements in range
    while (current && current->value <= end) {
        result.push_back(current->value);
        current = current->forward[0];
    }
    
    return result;
}
```

順序統計量の効率的な計算には、各ノードが部分リストのサイズ情報を保持する拡張が必要となる。具体的には、各ノードの各レベルにおいて、次のノードまでの距離（スキップする要素数）を記録する。この情報を用いることで、k番目の要素へのアクセスや、特定の要素の順位の計算がO(log n)で可能となる。

## 並行スキップリスト

マルチスレッド環境でのスキップリストの実装は、その構造的特性により比較的容易である。最も単純なアプローチは、粗粒度のロック（リーダー・ライターロック）を使用することだが、より高度な並行制御も可能である。

```mermaid
sequenceDiagram
    participant Thread1
    participant Thread2
    participant SkipList
    participant Node
    
    Thread1->>SkipList: search(25)
    Thread2->>SkipList: insert(15)
    
    Note over SkipList: Read operations can proceed concurrently
    
    Thread1->>Node: traverse levels
    Thread2->>SkipList: acquire write locks per level
    Thread2->>Node: update pointers
    Thread2->>SkipList: release locks
    Thread1->>SkipList: return result
```

細粒度ロックを使用する実装では、各ノードにロックを配置し、ハンドオーバーハンドロッキングを適用する。この手法では、現在のノードのロックを保持しながら次のノードのロックを取得し、その後現在のノードのロックを解放する。これにより、異なる部分での操作が並行して実行可能となる。

ロックフリーなスキップリストの実装も研究されており、CAS（Compare-And-Swap）操作を用いて実現される。挿入操作では、まず新しいノードを最下層に挿入し、その後上位レベルに順次追加していく。各ステップでCAS操作を使用することで、アトミックな更新を保証する。削除操作では、論理的削除と物理的削除の2段階で実装されることが多い。

## メモリ管理と最適化技法

実用的なスキップリストの実装では、メモリ効率が重要な考慮事項となる。ノードのメモリレイアウトを最適化することで、キャッシュ性能を向上させることができる。一つのアプローチは、低レベルのノード（レベル4以下など）では固定サイズの配列を使用し、それ以上のレベルでのみ動的配列を使用することである。

```cpp
template<typename T>
struct OptimizedNode {
    T value;
    uint8_t level;
    union {
        Node* directPointers[4];  // For levels 0-3
        struct {
            Node** dynamicPointers;
            uint8_t padding[sizeof(Node*) * 4 - sizeof(Node**)];
        };
    };
    
    Node* getForward(int lvl) {
        return (level <= 3) ? directPointers[lvl] : dynamicPointers[lvl];
    }
};
```

メモリプールの使用も効果的な最適化手法である。頻繁なノードの割り当てと解放を避けるため、事前に確保したメモリプールからノードを割り当てる。これにより、メモリ断片化を防ぎ、割り当てのオーバーヘッドを削減できる。

圧縮技法の適用により、メモリ使用量をさらに削減できる。例えば、連続する要素間の差分のみを保存する差分符号化や、上位レベルでは要素の要約情報のみを保持する手法が提案されている。これらの技法は、特に大規模なデータセットで有効である。

## パフォーマンス特性の詳細分析

スキップリストの実際のパフォーマンスは、理論的な期待値と実装の品質の両方に依存する。ベンチマーク結果によると、要素数が10^6程度の場合、検索操作は典型的に20-30回の比較で完了する。これは理論的な期待値log_2(10^6) ≈ 20と整合する。

```mermaid
graph LR
    subgraph "操作別の計算量"
        A["検索: O(log n)"] 
        B["挿入: O(log n)"]
        C["削除: O(log n)"]
        D["範囲検索: O(log n + k)"]
        E["最小値: O(1)"]
        F["最大値: O(log n)"]
    end
```

キャッシュ効率の観点から、スキップリストは平衡木と比較して不利な面がある。ポインタを辿る操作は本質的にランダムアクセスとなるため、キャッシュミスが発生しやすい。しかし、最下層での順次アクセスは良好なキャッシュ局所性を示し、範囲検索では特に効率的である。

実測値では、挿入操作のコストは検索操作の約1.5-2倍となることが多い。これは、レベル決定のオーバーヘッドとポインタ更新のコストによる。削除操作も同様のコストとなるが、メモリ解放の処理が追加される場合はさらに増加する可能性がある。

## 数学的基礎の深掘り

スキップリストの解析において中心的な役割を果たすのは、幾何分布とその性質である。レベルLのノードがレベルL+1にも存在する確率をpとすると、ノードが正確にレベルkを持つ確率はp^k(1-p)となる。この分布の期待値は p/(1-p) であり、分散は p/(1-p)^2 となる。

高さの分布についてより詳細に考察すると、n個のノードを持つスキップリストの高さHがhを超える確率は以下のように評価できる：

P(H > h) ≤ n × p^h

これは和集合の確率の上界を用いた評価である。より厳密な解析では、高さがlog_{1/p}(n) + c を超える確率は n^{1-c} のオーダーとなることが示される。

検索コストの詳細な解析では、レベルiでの期待ステップ数をS_iとすると、S_i = 1 + p×S_{i+1} という再帰関係が成立する。これを解くと、S_i = 1/(1-p) となり、全レベルでの総ステップ数は高さに比例することが分かる。

## 実装バリエーションと拡張

決定的スキップリストでは、要素の値やハッシュ値から決定的にレベルを計算する。例えば、要素xのレベルを trailing_zeros(hash(x)) として定義する方法がある。これにより、同じデータセットに対して常に同一の構造が生成され、デバッグやテストが容易になる。

適応的スキップリストは、アクセスパターンに基づいて構造を動的に調整する。頻繁にアクセスされる要素のレベルを増加させ、あまりアクセスされない要素のレベルを減少させることで、実際の使用パターンに最適化された構造を維持する。

```cpp
class AdaptiveSkipList {
private:
    struct Node {
        T value;
        int level;
        int accessCount;
        std::vector<Node*> forward;
        
        bool shouldPromote() {
            return accessCount > threshold && level < maxLevel;
        }
        
        bool shouldDemote() {
            return accessCount < threshold/2 && level > 0;
        }
    };
    
    void adaptStructure(Node* node) {
        if (node->shouldPromote()) {
            promoteNode(node);
        } else if (node->shouldDemote()) {
            demoteNode(node);
        }
    }
};
```

インターバルスキップリストは、点ではなく区間を要素として扱う拡張である。各ノードが区間の開始点と終了点を保持し、区間の重なり判定を効率的に行う。この構造は、スケジューリングや計算幾何学の問題で有用である。

## 実世界での応用例

Apache Cassandraでは、MemTableの実装にスキップリストが使用されている[^4]。書き込み性能とメモリ効率のバランスが評価され、採用に至っている。特に、並行書き込みのサポートが重要な要因となった。

MemcachedのLRU実装では、スキップリストを用いて有効期限順のアイテム管理を行っている。タイムスタンプをキーとしたスキップリストにより、期限切れアイテムの効率的な削除が可能となっている。

分散システムにおけるコンシステントハッシングの実装でも、スキップリストが活用される。ノードの追加・削除が頻繁に発生する環境で、ハッシュ空間上の効率的な検索を実現している。

[^4]: Apache Cassandra Documentation. "Storage Engine". https://cassandra.apache.org/doc/latest/architecture/storage-engine.html