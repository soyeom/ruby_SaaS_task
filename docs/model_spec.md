# モデル設計書

本システムは、ユーザー認証、ワークスペース管理、タスク管理、およびタスク進捗集計機能を実現するため、
以下のテーブル構成で設計する。

使用テーブル：
- users  
- workspaces  
- members  
- tasks  
- task_progresses  

---

## 1. テーブル定義

---

### 1.1 users テーブル

ユーザー情報（アカウント）を管理するテーブル。

| カラム名 | 型 | 制約 | 説明 |
|----------|----|------|------|
| id | bigint | PK | ユーザーID |
| login_id | string | UNIQUE / NOT NULL | ログイン用ID |
| password_digest | string | NOT NULL | パスワード（bcrypt 使用） |
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

本設計では `workspaces` テーブルに `owner_id` は持たせず、  
ワークスペースのオーナーは `members.role` によって管理する。

---

### 1.3 members テーブル（中間テーブル）

ユーザーとワークスペースの多対多関係を管理する中間テーブル。  
ワークスペース内での権限（オーナー / 一般メンバー）もここで管理する。

| カラム名 | 型 | 制約 | 説明 |
|----------|----|------|------|
| id | bigint | PK | メンバーID |
| user_id | bigint | FK(users.id) | ユーザーID |
| workspace_id | bigint | FK(workspaces.id) | ワークスペースID |
| role | integer | NOT NULL / default: 0 | 役割（owner=0, member=1） |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

#### 複合ユニーク制約

`UNIQUE(workspace_id, user_id)`

1 ワークスペース + 1 ユーザーにつき、  
集計結果は 1 件のみ保持する。

---

## 2. リレーション構成

### 2.1 users と workspaces

- 多対多関係（N : N）
- 中間テーブル：`members`

ユーザーは複数のワークスペースに所属できる。  
ワークスペースは複数のユーザーを持つ。

ワークスペース内の権限は `members.role` によって管理する。

---

### 2.2 workspaces と tasks

- 一対多関係（1 : N）

1つのワークスペースに複数のタスクが所属する。

---

### 2.3 users と tasks（担当者）

- 一対多関係（1 : N）

1人のユーザーが複数のタスクの担当者になることができる。

---

### 2.4 task_progresses の関係

- ワークスペース単位・ユーザー単位でタスク進捗を管理する。
- `(workspace_id, user_id)` の組み合わせごとに、進捗データは 1 件のみ保持する。

---

## ER 関係一覧

| エンティティ | 関係 | エンティティ | 備考 |
|------------|------|-------------|------|
| users | N : N | workspaces | members 経由 |
| workspaces | 1 : N | tasks | ワークスペース単位 |
| users | 1 : N | tasks | assignee |
| tasks | 集計対象 | task_progresses | batch 集計 |
| users | 1 : N | task_progresses | ユーザー単位集計 |
| workspaces | 1 : N | task_progresses | ワークスペース単位集計 |