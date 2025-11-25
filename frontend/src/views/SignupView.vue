<template lang="pug">
section.auth-page
  .auth-shell
    .auth-card
      .auth-header
        .logo-mark N
        h1.auth-title アカウントを作成
        p.auth-subtitle
          | タスク管理ワークスペースをはじめましょう。

      form.auth-form(@submit.prevent="onSubmit")
        .form-group
          label.form-label(for="login_id") ログインID
          input.form-input#login_id(
            type="text"
            v-model="form.login_id"
            placeholder="example_user"
            autocomplete="username"
          )

        .form-group
          label.form-label(for="password") パスワード
          input.form-input#password(
            type="password"
            v-model="form.password"
            placeholder="••••••••"
            autocomplete="new-password"
          )

        .form-group
          label.form-label(for="password_conf") パスワード(確認)
          input.form-input#password_conf(
            type="password"
            v-model="form.password_conf"
            placeholder="••••••••"
            autocomplete="new-password"
          )

        p.form-error(v-if="errorMessage") {{ errorMessage }}
        p.form-success(v-if="successMessage") {{ successMessage }}

        button.auth-button(type="submit" :disabled="isSubmitting")
          span(v-if="isSubmitting") 登録中...
          span(v-else) 登録する

      .auth-footer
        span すでにアカウントをお持ちの方は
        router-link.auth-link(to="/login") ログイン
</template>

<script setup>
import { reactive, ref } from "vue";
import { useRouter } from "vue-router";
import api from "@/api/client";

const router = useRouter();

const form = reactive({
  login_id: "",
  password: "",
  password_conf: "",
});

const errorMessage = ref("");
const successMessage = ref("");
const isSubmitting = ref(false);

const onSubmit = async () => {
  errorMessage.value = "";
  successMessage.value = "";

  if (!form.login_id || !form.password || !form.password_conf) {
    errorMessage.value = "login_id, password, password_conf は必須です。";
    return;
  }

  if (form.password !== form.password_conf) {
    errorMessage.value = "パスワードと確認用パスワードが一致しません。";
    return;
  }

  try {
    isSubmitting.value = true;
    const res = await api.post("/signup", {
      login_id: form.login_id,
      password: form.password,
      password_conf: form.password_conf,
    });

    successMessage.value = res.data?.message || "ユーザー登録が完了しました。";

    // 잠깐 메시지 보여주고 로그인 화면으로
    setTimeout(() => {
      router.push("/login");
    }, 900);
  } catch (err) {
    const data = err.response?.data;
    if (data?.details) {
      errorMessage.value = data.details.join(" / ");
    } else {
      errorMessage.value = data?.error || "ユーザー登録に失敗しました。";
    }
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<style scoped>
/* 스타일은 LoginView와 동일하게 맞추기 위해 복붙 */
.auth-page {
  min-height: 100vh;
  background: #f7f7f5;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
    sans-serif;
}

.auth-shell {
  width: 100%;
  max-width: 420px;
}

.auth-card {
  background: #ffffff;
  border-radius: 16px;
  padding: 32px 28px 24px;
  box-shadow: 0 18px 45px rgba(15, 23, 42, 0.08);
  border: 1px solid rgba(15, 23, 42, 0.06);
}

.auth-header {
  text-align: center;
  margin-bottom: 24px;
}

.logo-mark {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  border: 1px solid #111827;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 18px;
  margin: 0 auto 12px;
}

.auth-title {
  font-size: 20px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 4px;
}

.auth-subtitle {
  font-size: 13px;
  color: #6b7280;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.form-label {
  font-size: 13px;
  color: #4b5563;
}

.form-input {
  padding: 9px 10px;
  border-radius: 10px;
  border: 1px solid #d1d5db;
  font-size: 14px;
  outline: none;
  transition: border-color 0.15s ease, box-shadow 0.15s ease,
    background-color 0.15s ease;
  background-color: #f9fafb;
}

.form-input:focus {
  border-color: #6366f1;
  box-shadow: 0 0 0 1px rgba(99, 102, 241, 0.4);
  background-color: #ffffff;
}

.form-error {
  font-size: 12px;
  color: #b91c1c;
  margin-top: 4px;
}

.form-success {
  font-size: 12px;
  color: #15803d;
  margin-top: 4px;
}

.auth-button {
  margin-top: 4px;
  width: 100%;
  border: none;
  border-radius: 999px;
  padding: 9px 14px;
  font-size: 14px;
  font-weight: 500;
  background: #111827;
  color: #ffffff;
  cursor: pointer;
  transition: background-color 0.15s ease, transform 0.05s ease,
    box-shadow 0.15s ease;
}

.auth-button:hover:enabled {
  background: #0f172a;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.25);
  transform: translateY(-1px);
}

.auth-button:disabled {
  opacity: 0.6;
  cursor: default;
  box-shadow: none;
  transform: none;
}

.auth-footer {
  margin-top: 16px;
  font-size: 13px;
  color: #6b7280;
  text-align: center;
}

.auth-link {
  margin-left: 4px;
  color: #2563eb;
  text-decoration: none;
}

.auth-link:hover {
  text-decoration: underline;
}
</style>
