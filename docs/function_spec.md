# 機能設計書

## 1. 認証機能

### 🔹 ログイン処理

**URL:** `POST /login`

#### 処理フロー
1. ログイン画面からパラメータ送信
2. `AuthService.login` 呼び出し
3. ユーザー認証
4. 成功時: セッションに `user_id` 保存
5. ワークスペース一覧画面へ遷移

#### バリデーション
- login_id, password 必須
- 認証失敗時は 401 返却

---

### 🔹 サインアップ処理

**URL:** `POST /signup`

#### 処理フロー
1. 登録フォーム送信
2. `AuthService.signup` 呼び出し
3. ユーザー作成
4. 成功時レスポンス返却

#### バリデーション
- login_id, password, password_conf 必須
- パスワード確認一致
- login_id の一意性

---

### 🔹 ログアウト処理

**URL:** `DELETE /logout`

#### 処理内容
- セッションの `user_id` 削除
- ログアウトメッセージ返却

---

## 2. ワークスペース機能

### 🔹 ワークスペース一覧取得

**URL:** `GET /workspaces`

#### 処理フロー
1. ログインユーザー取得  
2. `current_user.workspaces` 取得  
3. `id, name` を JSON で返却  

#### バリデーション
- 認証必須（未認証時 401 / 403）  

---

### 🔹 ワークスペース詳細取得

**URL:** `GET /workspaces/:id`

#### 処理フロー
1. ワークスペース取得  
2. メンバー権限確認  
3. `WorkspaceService.show` 呼び出し  
4. 詳細データ返却  

#### バリデーション
- メンバー以外は 403  
- 存在しない場合は 404  

---

### 🔹 ワークスペース作成

**URL:** `POST /workspaces`

#### 処理フロー
1. name 受信  
2. `WorkspaceService.create` 呼び出し  
3. ワークスペース + オーナー生成  
4. 結果返却  

#### バリデーション
- name 必須  
- バリデーションエラー時 422  

---

### 🔹 ワークスペース更新

**URL:** `PUT /workspaces/:id`

#### 処理フロー
1. 対象ワークスペース取得  
2. 権限確認  
3. `WorkspaceService.update` 呼び出し  
4. 更新結果返却  

#### バリデーション
- name 必須  
- 失敗時 422  

---

### 🔹 ワークスペース削除

**URL:** `DELETE /workspaces/:id`

#### 処理内容
- 権限確認  
- ワークスペース削除  
- 完了メッセージ返却  

---

## 3. メンバー管理機能

### 🔹 メンバー一覧取得

**URL:** `GET /workspaces/:id`

#### 処理フロー
1. ワークスペース取得  
2. メンバー権限確認  
3. `WorkspaceService.show` により members 情報を取得  
4. メンバー一覧をレスポンスとして返却  

#### バリデーション
- 非メンバーは 403 返却  
- 対象が存在しない場合は 404  

---

### 🔹 メンバー追加

**URL:** `POST /workspaces/:workspace_id/members`

#### 処理フロー
1. ワークスペース取得  
2. オーナー権限確認  
3. `MemberService.add_member` 呼び出し  
4. メンバー追加結果返却  

#### バリデーション
- login_id 必須  
- ユーザー未存在時 404  
- 既存メンバーの場合 422  
- role 不正時 422

---

### 🔹 メンバー削除

**URL:** `DELETE /workspaces/:workspace_id/members/:id`

#### 処理フロー
1. ワークスペース取得  
2. ログインユーザーがオーナーか確認  
3. 対象メンバー取得  
4. 対象メンバーがオーナーでないことを確認  
5. `MemberService.remove_member` 実行  
6. メンバー削除処理  
7. 完了レスポンス返却  

#### バリデーション / エラー
- ログインユーザーがオーナーでない場合 → **403**（オーナーのみ実行可能）  
- 対象メンバー未存在 → **404**  
- 削除対象がオーナーの場合 → **422**（オーナーは削除できません。）  


---

## 4. タスク機能

### 🔹 タスク一覧取得

**URL:** `GET /workspaces/:workspace_id/tasks`

#### 処理フロー
1. ワークスペース取得  
2. メンバー権限確認  
3. `TaskService.list` 呼び出し（status, category, assignee_id でフィルタ）  
4. タスク一覧を JSON で返却（id, title, status, category, assignee_id）  

#### バリデーション
- 非メンバーは 403 返却  
- 不正なステータス指定時は 400 返却（`不正なステータスが指定されました。`）  

---

### 🔹 タスク詳細取得

**URL:** `GET /workspaces/:workspace_id/tasks/:id`

#### 処理フロー
1. ワークスペース取得  
2. メンバー権限確認  
3. ワークスペース配下からタスク取得  
4. `TaskService.show` 呼び出し  
5. タスク詳細を JSON で返却  

#### バリデーション
- 非メンバーは 403 返却  
- タスク未存在時は 404 返却  

---

### 🔹 タスク作成

**URL:** `POST /workspaces/:workspace_id/tasks`

#### 処理フロー
1. パラメータ受信（title, description, status, category, assignee_id）  
2. `TaskService.create` 呼び出し  
3. タスク新規作成  
4. 作成メッセージ + 作成されたタスク情報を返却  

#### バリデーション
- title 必須（未入力時は 400 返却、`タスクタイトルは必須です。`）  
- モデルバリデーションエラー時は 422 返却  

---

### 🔹 タスク更新

**URL:** `PUT /workspaces/:workspace_id/tasks/:id`

#### 処理フロー
1. タスク取得  
2. メンバー権限確認  
3. `TaskService.update` 呼び出し（title, description, status, category, assignee_id を更新）  
4. 更新メッセージ + 更新後タスク情報を返却  

#### バリデーション
- モデルバリデーションエラー時は 422 返却  

---

### 🔹 タスク削除

**URL:** `DELETE /workspaces/:workspace_id/tasks/:id`

#### 処理内容
- タスク取得  
- メンバー権限確認  
- タスク削除  
- 削除完了メッセージ返却  

---

## 5. タスク進捗機能

### 🔹 タスク進捗一覧取得

**URL:** `GET /workspaces/:workspace_id/task_progresses`

#### 処理フロー
1. ワークスペース取得  
2. メンバー権限確認  
3. `TaskProgress` を `includes(:user)` で取得  
4. 担当者ごとの進捗データを整形して JSON で返却  

#### バリデーション
- 非メンバーは 403 返却  
- ワークスペース未存在時は 404 返却  

---

### 🔹 タスク進捗集計バッチ

**実行コマンド:** `rake task_progress:aggregate`

#### 処理フロー
1. 全ワークスペースを取得  
2. 各ワークスペースの担当者付きタスクを取得  
3. 担当者ごとに以下を集計  
   - 総タスク数  
   - 完了タスク数（status = done）  
   - 完了率（％）  
4. `TaskProgress` テーブルに保存  
5. `aggregated_at` に集計日時を記録  

#### バリデーション
- ワークスペースにタスクが存在しない場合はスキップ  
- 担当者が存在しない場合は処理対象外  

---

### 🔹 タスク進捗自動集計デーモン

**実行コマンド:** `rake task_progress:daemon`

#### 処理フロー
1. `Rufus::Scheduler` を起動  
2. 5分ごとに `task_progress:aggregate` を実行  
3. 定期的にタスク進捗データを更新  

#### バリデーション
- サーバー稼働中のみ有効  
- バッチ実行失敗時はログ出力のみ行う  

---

---

## 6. テスト機能（自動テスト）

### 🔹 ワークスペース一覧アクセス制御テスト

**対象:** `GET /workspaces`  
**テスト種別:** リクエストテスト  
**ファイル:** `spec/requests/workspaces_spec.rb`

#### 処理フロー
1. 未ログイン状態で `/workspaces` にアクセス  
2. 401 Unauthorized が返却されることを確認  
3. `/login` によりログイン処理実行  
4. 同一セッションで `/workspaces` に再度アクセス  
5. 自分が所属するワークスペース一覧が取得できることを確認  

#### バリデーション
- 未ログイン時は 401 が返ること  
- ログイン後は 200 が返ること  
- レスポンスに自分の所属ワークスペースが含まれること  

---

### 🔹 タスク作成時バリデーションテスト

**対象:** `Task` モデル  
**テスト種別:** モデルテスト  
**ファイル:** `spec/models/task_spec.rb`

#### 処理フロー
1. タイトルあり + workspace ありで Task を生成  
2. `valid?` が `true` となることを確認  
3. タイトル空文字で Task を生成  
4. `valid?` が `false` となることを確認  

#### バリデーション
- タイトルが空の場合は無効になること  
- `errors[:title]` にエラーメッセージが含まれること  

---