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


  ---

  ## 2. ワークスペース管理機能

### 2.1 ワークスペース一覧取得 API

- **エンドポイント**
    - `GET /workspaces`
- **役割**
    - ログインユーザーが所属しているワークスペース一覧を取得する。
    - `members` テーブルを通して該当ワークスペースを取得する。
- **前提条件**
    - 認証済みユーザーのみアクセス可能
    - 未ログインの場合は `401 Unauthorized` を返却する。
- **処理フロー**
    1. `current_user` を取得。
    2. `current_user.workspaces` により所属ワークスペース一覧を取得。
    3. 各ワークスペースの `id`, `name` をJSON形式で返却。
- **レスポンス例**
    - 成功時（200）
    
    ```json
    [
      {
        "id": 5,
        "name": "テストワークスペース"
      },
      {
        "id": 6,
        "name": "開発用ワークスペース"
      }
    ]
    ```
    
- 未ログイン時（401）
```json
{
  "error": "ログインが必要です。"
}
```
### 2.2 ワークスペース作成 API

- **エンドポイント**
    - `POST /workspaces`
- **役割**
    - 新しいワークスペースを作成する。
    - 作成ユーザーを `members` テーブルに `owner` として自動登録する。
- **リクエストパラメータ（JSON）**
    
    
    | 項目名 | キー | 型 | 必須 | 備考 |
    | --- | --- | --- | --- | --- |
    | ワークスペース名 | name | string | 必須 | 空文字不可 |
- **バリデーション**
    - 必須チェック（コントローラレベル）
    - `name` が空の場合 → HTTP 400 (bad_request) を返却
    - メッセージ：ワークスペース名は必須です。
- **作成処理**
    - 以下の処理を `Workspace.transaction` 内で実行する。
        1. `Workspace.create!(name: params[:name])`
        2. `workspace.members.create!(user: current_user, role: :owner)`
    - ※ いずれかが失敗した場合は、自動的にロールバックされる。
- **処理フロー**
    1. `params[:name]` を取得。
    2. 空チェック。
    3. トランザクション開始。
    4. ワークスペース作成。
    5. 作成ユーザーを `owner` として `members` に登録。
    6. 成功時は 201 を返却。
    7. 失敗時は 422 を返却。
- **レスポンス例**
    - 成功時（201）
        
        ```json
        {
          "message": "ワークスペースを作成しました。",
          "workspace": {
            "id": 5,
            "name": "テストワークスペース"
          }
        }
        ```
        
    - バリデーションエラー（400）
        
        ```json
        {
          "error": "ワークスペース名は必須です。"
        }
        ```
        
    - 保存失敗時（422）
        
        ```json
        {
          "error": "ワークスペースの作成に失敗しました。",
          "details": [
            "Name can't be blank"
          ]
        }
        ```
        

### 2.3 ワークスペース詳細取得 API

- **エンドポイント**
    - `GET /workspaces/:id`
- **役割**
    - 指定されたワークスペースの詳細情報を取得する。
- **アクセス制御**
    - 対象ワークスペースに所属しているユーザーのみアクセス可能。
    - 判定条件
        
        ```ruby
        current_user.workspaces.exists?(id: params[:id])
        ```
        
- **処理フロー**
    1. `params[:id]` を取得。
    2. ワークスペース取得。
    3. 所属メンバーかどうかをチェック。
    4. 詳細情報を返却。
- **レスポンス例（200）**
    
    ```json
    {
      "id": 5,
      "name": "テストワークスペース"
    }
    ```
    

### 2.4 ワークスペース削除 API

- **エンドポイント**
    - `DELETE /workspaces/:id`
- **役割**
    - 指定したワークスペースを削除する。
- **アクセス制御**
    - オーナー権限を持つユーザーのみ削除可能。
- **削除処理**
    - `@workspace.destroy` を実行。
- **レスポンス例**
    
    ```json
    {
      "message": "ワークスペースを削除しました。"
    }
    ```
    

### 2.5 ワークスペースアクセス制御仕様

- 各ワークスペースへのアクセスは `members` テーブルに登録されているユーザーのみ可能。
- **判定条件：**
    
    ```ruby
    current_user.workspaces.exists?(id: params[:id])
    ```
    
- **アクセス拒否時レスポンス：**
    
    ```json
    {
      "error": "アクセス権限がありません。"
    }
    ```
    
    - HTTP ステータス: 403 Forbidden

### 2.6 未ログイン時の共通挙動

- セッションが存在しない場合、以下を返却する。
    
    ```json
    {
      "error": "ログインが必要です。"
    }
    ```
    
    - HTTPステータス: 401 Unauthorized

---