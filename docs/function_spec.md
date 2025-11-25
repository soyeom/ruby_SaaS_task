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
