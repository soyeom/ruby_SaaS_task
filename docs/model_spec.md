# モデル設計書

本システムは、ユーザー認証、ワークスペース管理、タスク管理、およびタスク進捗集計機能を実現するため、以下のテーブル構成で設計する。

使用テーブル：
- users  
- workspaces  
- members  
- tasks  
- task_progress

---

## 1. テーブル定義

### 1.1 users テーブル

ユーザー情報（アカウント）を管理するテーブル。

| カラム名 | 型 | 制約 | 説明 |
|----------|----|------|------|
| id | bigint | PK | ユーザーID |
| login_id | string | UNIQUE / NOT NULL | ログイン用ID |
| password | string | NOT NULL | パスワード |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

---

### 1.2 workspaces テーブル

ワークスペース（組織・チーム）を管理するテーブル。

| カラム名 | 型 | 制約 | 説明 |
|----------|----|------|------|
| id | bigint | PK | ワークスペースID |
| name | string | NOT NULL | ワークスペース名 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

---

### 1.3 members テーブル（中間テーブル）

ユーザーとワークスペースの多対多関係を管理する中間テーブル。

| カラム名 | 型 | 制約 | 説明 |
|----------|----|------|------|
| id | bigint | PK | メンバーID |
| user_id | bigint | FK(users.id) | ユーザーID |
| workspace_id | bigint | FK(workspaces.id) | ワークスペースID |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

複合ユニーク制約：  
`UNIQUE(user_id, workspace_id)`

→ 同じユーザーが同じワークスペースに重複登録されないようにする。

---

### 1.4 tasks テーブル

ワークスペース内のタスク情報を管理するテーブル。

| カラム名 | 型 | 制約 | 説明 |
|----------|----|------|------|
| id | bigint | PK | タスクID |
| title | string | NOT NULL | タスク名 |
| description | text | NULL可 | 詳細説明 |
| status | integer | NOT NULL / default: 0 | 状態（todo=0, done=1） |
| category | string | NULL可 | カテゴリ |
| workspace_id | bigint | FK(workspaces.id) | 所属ワークスペースID |
| assignee_id | bigint | FK(users.id) | 担当ユーザーID |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

ステータスは enum として以下のように管理する：  
- 0 : todo  
- 1 : done  

---

### 1.5 task_progress テーブル

Rakeバッチ処理によって集計されたタスク進捗情報を保存するテーブル。

| カラム名 | 型 | 制約 | 説明 |
|----------|----|------|------|
| id | bigint | PK | 集計ID |
| workspace_id | bigint | FK(workspaces.id) | ワークスペースID |
| user_id | bigint | FK(users.id) | ユーザーID |
| total_tasks | integer | NOT NULL | 総タスク数 |
| completed_tasks | integer | NOT NULL | 完了タスク数 |
| completion_rate | integer | NOT NULL | 進捗率（%） |
| aggregated_at | datetime | NOT NULL | 集計実行日時 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

複合ユニーク制約：  
`UNIQUE(workspace_id, user_id)`

→ 1ワークスペース + 1ユーザーにつき、集計結果は1件のみ保持する。

---

## 2. リレーション構成

### 2.1 users と workspaces

- 多対多関係（N:N）
- 中間テーブル: `members`


ユーザーは複数のワークスペースに所属可能。  
ワークスペースは複数のユーザーを持つ。

---

### 2.2 workspaces と tasks

- 一対多関係（1:N）


1つのワークスペースに複数のタスクが所属する。

---

### 2.3 users と tasks（担当者）

- 一対多関係（1:N）


1人のユーザーが複数のタスクの担当者になることができる。

---

### 2.4 task_progress の関係


- ワークスペース単位、ユーザー単位でタスク進捗を管理する。
- `(workspace_id, user_id)` の組み合わせごとに1件のみ保持する。

---

## 3. ER 図（テキスト表現）

以下は本システムのER構造をテキストで表した図である。


---