<template lang="pug">
section.auth-page
  .auth-shell
    .auth-card
      .auth-header
        .logo-mark X
        h1.auth-title タスク管理ツールへようこそ
        p.auth-subtitle
          | ログインしてワークスペースとタスクを管理しましょう。

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
            autocomplete="current-password"
          )

        p.form-error(v-if="errorMessage") {{ errorMessage }}

        button.auth-button(type="submit" :disabled="isSubmitting")
          span(v-if="isSubmitting") ログイン中...
          span(v-else) ログイン

      .auth-footer
        span アカウントをお持ちでない方は
        router-link.auth-link(to="/signup") サインアップ
</template>

<script setup>
import { reactive, ref } from "vue";
import { useRouter } from "vue-router";
import api from "@/api/client"; // src/api/client.js 에서 Axios 인스턴스 export 했다고 가정

const router = useRouter();

const form = reactive({
  login_id: "",
  password: "",
});

const errorMessage = ref("");
const isSubmitting = ref(false);

const onSubmit = async () => {
  errorMessage.value = "";
  if (!form.login_id || !form.password) {
    errorMessage.value = "login_id と password は必須です。";
    return;
  }

  try {
    isSubmitting.value = true;
    const res = await api.post("/login", {
      login_id: form.login_id,
      password: form.password,
    });

    console.log("login success:", res.data);
    router.push("/workspaces");
  } catch (err) {
    const data = err.response?.data;
    errorMessage.value = data?.error || "ログインに失敗しました。";
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<style scoped>
.auth-page {
  min-height: 100vh;
  background: #f7f7f5; /* Notion 같은 밝은 배경 */
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
