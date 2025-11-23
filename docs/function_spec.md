# 機能設計書

本ドキュメントでは、本システムの主要機能（認証機能・ワークスペース機能）について、
API 単位の処理フローおよびバリデーション仕様を記載する。

対象機能（現時点）:
- ユーザー認証機能（サインアップ・ログイン・ログアウト）
- ワークスペース管理機能（一覧取得・作成）

---

## 1. 認証機能

### 1.1 サインアップ API

- **エンドポイント**  
  - `POST /signup`

- **役割**  
  - 新規ユーザーアカウントを作成する。  
  - パスワードは `has_secure_password` によりハッシュ化し、`password_digest` カラムに保存する。

- **リクエストパラメータ（JSON）**

| 項目名          | キー             | 型     | 必須 | 備考                          |
|-----------------|------------------|--------|------|-------------------------------|
| ログインID      | `login_id`       | string | 必須 | 一意である必要がある          |
| パスワード      | `password`       | string | 必須 | ハッシュ化して保存される      |
| パスワード確認  | `password_conf`  | string | 必須 | `password` と一致必須         |

- **バリデーション**

  - 必須チェック（コントローラレベル）
    - `login_id`, `password`, `password_conf` がいずれか空の場合  
      → HTTP 400 (`bad_request`) を返却
      - エラーメッセージ:  
        `login_id, password, password_conf は必須です。`

  - パスワード確認（モデルレベル）
    - `User` モデルで `has_secure_password` を利用しているため、
      `password` と `password_confirmation` が一致しない場合は自動でバリデーションエラーとなる。
      - コントローラでは `password_confirmation: password_conf` として渡す。

  - ログインIDの一意制約
    - `login_id` に対して `UNIQUE` 制約 + `validates :login_id, uniqueness: true`。
    - 重複登録の場合は `user.save` が失敗し、エラー配列にメッセージが格納される。

- **処理フロー**

  1. `params` から `login_id`, `password`, `password_conf` を取得。
  2. 必須項目が空の場合、400 エラーとメッセージを返して終了。
  3. `User.new(login_id: ..., password: ..., password_confirmation: ...)` を生成。
  4. `user.save` を実行。
     - 成功時: ユーザー情報がDBに作成される。
     - 失敗時: バリデーションエラー内容を `user.errors.full_messages` で取得。
  5. 成功時: HTTP 201 と共に成功メッセージ＋ユーザー情報を返却。
  6. 失敗時: HTTP 422 (`unprocessable_entity`) とエラー内容を返却。

- **レスポンス例**

  - 成功時（201）

    ```json
    {
      "message": "ユーザー登録が完了しました。",
      "user": {
        "id": 1,
        "login_id": "test_user"
      }
    }
    ```

  - 失敗時（422）

    ```json
    {
      "error": "ユーザー登録に失敗しました。",
      "details": [
        "Login has already been taken",
        "Password confirmation doesn't match Password"
      ]
    }
    ```

---

### 1.2 ログイン API

- **エンドポイント**  
  - `POST /login`

- **役割**  
  - ログインIDとパスワードを受け取り、認証に成功した場合にセッション情報を設定する。  
  - Rails のセッション機能（Cookie ベース）を使用し、`session[:user_id]` にログインユーザーのIDを保存する。

- **リクエストパラメータ（JSON）**

| 項目名     | キー        | 型     | 必須 | 備考              |
|------------|-------------|--------|------|-------------------|
| ログインID | `login_id`  | string | 必須 |                   |
| パスワード | `password`  | string | 必須 | 平文で受け取りOK（内部でハッシュと比較） |

- **バリデーション**

  - 必須チェック
    - `login_id`, `password` が空の場合:
      - HTTP 400 (`bad_request`)
      - メッセージ: `login_id と password は必須です。`

  - 認証チェック
    - `User.find_by(login_id: ...)` でユーザーを検索。
    - 見つかったユーザーに対して `user.authenticate(password)` を実行。
      - 成功: パスワード一致 → ユーザーオブジェクトを返す。
      - 失敗: `false` を返す（または `nil`）。

- **処理フロー**

  1. `login_id`, `password` をパラメータから取得。
  2. 必須チェックで空の場合は 400 エラーを返して終了。
  3. `User.find_by(login_id: login_id)` でユーザーを検索。
  4. `user&.authenticate(password)` で認証を実施。
  5. 認証成功時:
     - `session[:user_id] = user.id` をセット。
     - 200 OK とメッセージ＋ユーザー情報を返却。
  6. 認証失敗時:
     - 401 Unauthorized を返却。
     - メッセージ: `ログインIDまたはパスワードが正しくありません。`

- **レスポンス例**

  - 成功時（200）

    ```json
    {
      "message": "ログインに成功しました。",
      "user": {
        "id": 1,
        "login_id": "test_user"
      }
    }
    ```

  - 失敗時（401）

    ```json
    {
      "error": "ログインIDまたはパスワードが正しくありません。"
    }
    ```

---

### 1.3 ログアウト API

- **エンドポイント**  
  - `DELETE /logout`

- **役割**  
  - 現在のセッションから `user_id` を削除し、ログイン状態を解除する。

- **処理フロー**

  1. `session.delete(:user_id)` を実行。
  2. 200 OK とメッセージを返却。

- **レスポンス例**

  ```json
  {
    "message": "ログアウトしました。"
  }