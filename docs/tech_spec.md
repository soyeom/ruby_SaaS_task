# 機能設計書（認証機能）

---

## 1. 対象機能
- ログイン機能
- サインアップ機能
- ログアウト機能

---

## 2. 画面単位の処理フロー

### ① ログイン画面

1. ユーザーが `login_id` と `password` を入力  
2. ログインボタン押下  
3. フロントエンドから `POST /login` を呼び出す  
4. サーバー側で認証処理を実行  
5. 認証成功 → `/workspaces` 画面へ遷移  
   認証失敗 → エラーメッセージを表示  

---

### ② サインアップ画面

1. ユーザーが `login_id`, `password`, `password_conf` を入力  
2. 登録ボタン押下  
3. フロントエンドから `POST /signup` を呼び出す  
4. ユーザー作成処理を実行  
5. 成功 → ログイン画面へ遷移  
   失敗 → エラーメッセージを表示  

---

## 3. API仕様

### 🔹 POST /login

| 項目 | 内容 |
|------|------|
| URL | `/login` |
| Method | POST |
| Request | `{ login_id, password }` |
| Success | 200 OK |
| Error | 400 Bad Request / 401 Unauthorized |

---

### 🔹 POST /signup

| 項目 | 内容 |
|------|------|
| URL | `/signup` |
| Method | POST |
| Request | `{ login_id, password, password_conf }` |
| Success | 201 Created |
| Error | 400 Bad Request / 422 Unprocessable Entity |

---

### 🔹 DELETE /logout

| 項目 | 内容 |
|------|------|
| URL | `/logout` |
| Method | DELETE |
| Success | 200 OK |

---

## 4. バリデーション仕様

### ■ ログイン

| 項目 | バリデーション内容 |
|------|----------------|
| login_id | 必須 |
| password | 必須 |
| 認証 | login_id + password の一致必須 |

---

### ■ サインアップ

| 項目 | バリデーション内容 |
|------|----------------|
| login_id | 必須 + 一意 |
| password | 必須 |
| password_conf | 必須 + password と一致 |
