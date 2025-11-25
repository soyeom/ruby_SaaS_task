<template lang="pug">
section.task-detail-page
  .task-shell
    div(v-if="loading") 読み込み中…

    div(v-else-if="!task && errorMessage")
      p.form-error {{ errorMessage }}
      button.secondary-button(@click="goBack") ワークスペースに戻る

    .task-card(v-else)
      // ── 헤더: 제목 + ID 정보
      header.card-header
        p.breadcrumb タスク
        input.task-title-input(
          type="text"
          v-model="title"
          placeholder="タイトル"
        )

      form(@submit.prevent="onUpdate")
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
              span(v-if="saving") 更新中…
              span(v-else) タスクを更新

            button.danger-button(type="button" :disabled="deleting" @click="onDelete")
              span(v-if="deleting") 削除中…
              span(v-else) タスクを削除

            button.secondary-button(type="button" @click="goBack") ← ワークスペースに戻る
</template>

<script setup>
import { onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import api from "../api/client";

const route = useRoute();
const router = useRouter();

const task = ref(null);

const title = ref("");
const description = ref("");
const status = ref("todo");
const category = ref("");
const assigneeId = ref("");

const members = ref([]);

const loading = ref(false);
const saving = ref(false);
const deleting = ref(false);

const errorMessage = ref("");
const successMessage = ref("");

const workspaceId = () => route.params.workspaceId;
const taskId = () => route.params.taskId;

const fetchMembers = async () => {
  try {
    const res = await api.get(`/workspaces/${workspaceId()}`);
    // show 응답에 { members: [...] } 있다고 가정
    members.value = res.data.members || [];
  } catch (err) {
    console.error("メンバー情報の取得に失敗しました:", err);
  }
};

const fetchTask = async () => {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    const res = await api.get(
      `/workspaces/${workspaceId()}/tasks/${taskId()}`
    );
    // show: { id, title, description, status, category, workspace_id, assignee_id }
    task.value = res.data;
    title.value = res.data.title;
    description.value = res.data.description || "";
    status.value = res.data.status;
    category.value = res.data.category || "";
    assigneeId.value = res.data.assignee_id || "";
  } catch (err) {
    const statusCode = err.response?.status;
    const data = err.response?.data;
    if (statusCode === 401 || statusCode === 403) {
      router.push("/login");
      return;
    }
    if (statusCode === 404) {
      errorMessage.value = "タスクが見つかりませんでした。";
    } else {
      console.error("タスク詳細取得に失敗しました:", err);
      errorMessage.value =
        data?.error || "タスクの取得に失敗しました。";
    }
    task.value = null;
  } finally {
    loading.value = false;
  }
};

const onUpdate = async () => {
  errorMessage.value = "";
  successMessage.value = "";

  if (!title.value.trim()) {
    errorMessage.value = "タスクタイトルは必須です。";
    return;
  }

  try {
    saving.value = true;

    const res = await api.put(
      `/workspaces/${workspaceId()}/tasks/${taskId()}`,
      {
        title: title.value.trim(),
        description: description.value.trim(),
        status: status.value,
        category: category.value.trim(),
        assignee_id: assigneeId.value || null,
      }
    );

    task.value = res.data.task;
    successMessage.value = res.data.message || "タスクを更新しました。";
  } catch (err) {
    const data = err.response?.data;
    console.error("タスク更新に失敗しました:", err);
    if (data?.details) {
      errorMessage.value = data.details.join(" / ");
    } else {
      errorMessage.value =
        data?.error || "タスクの更新に失敗しました。";
    }
  } finally {
    saving.value = false;
  }
};

const onDelete = async () => {
  const ok = window.confirm(
    "本当にこのタスクを削除しますか？この操作は元に戻せません。"
  );
  if (!ok) return;

  try {
    deleting.value = true;
    await api.delete(`/workspaces/${workspaceId()}/tasks/${taskId()}`);
    router.push(`/workspaces/${workspaceId()}`);
  } catch (err) {
    const data = err.response?.data;
    console.error("タスク削除に失敗しました:", err);
    errorMessage.value = data?.error || "タスクの削除に失敗しました。";
  } finally {
    deleting.value = false;
  }
};

const goBack = () => {
  router.push(`/workspaces/${workspaceId()}`);
};

onMounted(() => {
  fetchTask();
  fetchMembers();
});
</script>

<style scoped>
.task-detail-page {
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

.card-title {
  font-size: 18px;
  font-weight: 600;
  color: #111827;
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

.primary-button:disabled,
.danger-button:disabled {
  opacity: 0.6;
  cursor: default;
}

.danger-button {
  border: none;
  border-radius: 999px;
  padding: 7px 14px;
  font-size: 14px;
  font-weight: 500;
  background: #ef4444;
  color: #ffffff;
  cursor: pointer;
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