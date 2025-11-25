<template lang="pug">
section.task-create-page
  .task-shell
    .task-card
      // ── 헤더: 제목 입력
      header.card-header
        p.breadcrumb タスク / 新規作成
        input.task-title-input(
          type="text"
          v-model="title"
          placeholder="タイトル"
        )

      form(@submit.prevent="onCreate")
        // ── 메타 정보 (상태 / 카테고리 / 담당자)
        .meta-row
          .meta-field
            label.form-label(for="status") ステータス
            select.form-input#status(v-model="status")
              option(value="todo") 未着手
              option(value="doing") 進行中
              option(value="done") 完了

          .meta-field
            label.form-label(for="category") カテゴリ
            input.form-input#category(
              type="text"
              v-model="category"
              placeholder="例) バグ / 機能 / 調査"
            )

          .meta-field
            label.form-label(for="assignee_id") 担当者
            select.form-input#assignee_id(v-model="assigneeId")
              option(value="") 担当者なし
              option(
                v-for="m in members"
                :key="m.user ? m.user.id : m.id"
                :value="m.user ? m.user.id : m.id"
              )
                | {{ m.user ? m.user.login_id : m.login_id }}

        // ── 설명 영역
        .form-group
          label.form-label(for="description") 説明
          textarea.form-textarea#description(
            v-model="description"
            rows="5"
            placeholder="タスクの詳細やメモを記載してください。"
          )

        p.form-error(v-if="errorMessage") {{ errorMessage }}
        p.form-success(v-if="successMessage") {{ successMessage }}

        footer.card-footer
          .button-row
            button.primary-button(type="submit" :disabled="saving")
              span(v-if="saving") 作成中…
              span(v-else) タスクを作成

            button.secondary-button(type="button" @click="goBack") ← ワークスペースに戻る
</template>

<script setup>
import { ref, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import api from "../api/client";

const route = useRoute();
const router = useRouter();

const title = ref("");
const description = ref("");
const status = ref("todo");
const category = ref("");
const assigneeId = ref("");

const members = ref([]);

const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const workspaceId = () => route.params.workspaceId;

const fetchMembers = async () => {
  try {
    const res = await api.get(`/workspaces/${workspaceId()}`);
    members.value = res.data.members || [];
  } catch (err) {
    console.error("メンバー情報の取得に失敗しました:", err);
  }
};

const onCreate = async () => {
  errorMessage.value = "";
  successMessage.value = "";

  if (!title.value.trim()) {
    errorMessage.value = "タスクタイトルは必須です。";
    return;
  }

  try {
    saving.value = true;

    const res = await api.post(`/workspaces/${workspaceId()}/tasks`, {
      title: title.value.trim(),
      description: description.value.trim(),
      status: status.value,
      category: category.value.trim(),
      assignee_id: assigneeId.value || null,
    });

    successMessage.value = res.data.message || "タスクを作成しました。";

    router.push(`/workspaces/${workspaceId()}`);
  } catch (err) {
    const data = err.response?.data;
    console.error("タスク作成に失敗しました:", err);
    if (data?.details) {
      errorMessage.value = data.details.join(" / ");
    } else {
      errorMessage.value =
        data?.error || "タスクの作成に失敗しました。";
    }
  } finally {
    saving.value = false;
  }
};

const goBack = () => {
  router.push(`/workspaces/${workspaceId()}`);
};

onMounted(() => {
  fetchMembers();
});
</script>

<style scoped>
.task-create-page {
  min-height: 100vh;
  background: #f7f7f5;
  display: flex;
  justify-content: center;
  padding: 32px 16px;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
    sans-serif;
}

.task-shell {
  width: 100%;
  max-width: 720px;
}

/* 카드 전체 */
.task-card {
  background: #ffffff;
  border-radius: 14px;
  padding: 20px 20px 16px;
  border: 1px solid rgba(15, 23, 42, 0.08);
  box-shadow: 0 10px 30px rgba(15, 23, 42, 0.04);
}

/* 헤더 */
.card-header {
  margin-bottom: 16px;
}

.breadcrumb {
  font-size: 12px;
  color: #9ca3af;
  margin-bottom: 4px;
}

.task-title-input {
  width: 100%;
  border: none;
  font-size: 20px;
  font-weight: 600;
  padding: 4px 0;
  margin-top: 4px;
  outline: none;
  background: transparent;
}

/* 폼 공통 */
.form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 12px;
}

.form-label {
  font-size: 13px;
  color: #4b5563;
}

.form-input {
  padding: 8px 10px;
  border-radius: 10px;
  border: 1px solid #d1d5db;
  font-size: 14px;
  background-color: #f9fafb;
  outline: none;
}

.form-input:focus {
  border-color: #6366f1;
  background-color: #ffffff;
  box-shadow: 0 0 0 1px rgba(99, 102, 241, 0.4);
}

.form-textarea {
  padding: 8px 10px;
  border-radius: 10px;
  border: 1px solid #d1d5db;
  font-size: 14px;
  background-color: #f9fafb;
  outline: none;
  resize: vertical;
}

.form-textarea:focus {
  border-color: #6366f1;
  background-color: #ffffff;
  box-shadow: 0 0 0 1px rgba(99, 102, 241, 0.4);
}

/* 메타 영역 (상태/카테고리/담당자) */
.meta-row {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
  margin-bottom: 14px;
}

.meta-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

/* 메시지 */
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

/* 버튼 영역 */
.card-footer {
  margin-top: 16px;
}

.button-row {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 4px;
}

.primary-button {
  border: none;
  border-radius: 999px;
  padding: 7px 14px;
  font-size: 14px;
  font-weight: 500;
  background: #111827;
  color: #ffffff;
  cursor: pointer;
}

.primary-button:disabled {
  opacity: 0.6;
  cursor: default;
}

.secondary-button {
  border-radius: 999px;
  border: 1px solid #d1d5db;
  padding: 6px 12px;
  font-size: 13px;
  background: #ffffff;
  color: #374151;
  cursor: pointer;
}
</style>
