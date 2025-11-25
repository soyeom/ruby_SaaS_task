<template lang="pug">
section.workspace-detail-page
  .workspace-shell
    div(v-if="loading") 読み込み中…

    div(v-else-if="!workspace && errorMessage")
      p.form-error {{ errorMessage }}
      button.secondary-button(@click="goBack") 一覧に戻る

    .workspace-card(v-else-if="workspace")
      header.card-header
        h1.card-title ワークスペース詳細

      // ワークスペース名編集
      .form-group
        label.form-label(for="name") ワークスペース名
        input.form-input#name(
          type="text"
          v-model="editName"
        )

      p.form-error(v-if="errorMessage") {{ errorMessage }}
      p.form-success(v-if="successMessage") {{ successMessage }}

      // タスク一覧セクション
      .workspace-subsections
        .sub-card
          .sub-card-header
            h2.sub-title タスク
            button.sub-action-button(@click="goToTaskCreate") ＋ タスク

          ul.task-list(v-if="tasks.length > 0")
            li.task-item(
              v-for="t in tasks"
              :key="t.id"
              @click="goToTask(t.id)"
            )
              span.task-title {{ t.title }}
              span.task-status {{ statusLabel(t.status) }}

          p.sub-desc(v-else)
            | このワークスペースに紐づくタスクはまだありません。

      // 카드 맨 하단 버튼들
      footer.card-footer
        .button-row
          button.primary-button(:disabled="saving" @click="onUpdate")
            span(v-if="saving") 更新中…
            span(v-else) ワークスペース名を更新

          button.danger-button(:disabled="deleting" @click="onDelete")
            span(v-if="deleting") 削除中…
            span(v-else) ワークスペースを削除

          button.secondary-button(type="button" @click="goBack") ← ワークスペース一覧に戻る
</template>

<script setup>
import { onMounted, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import api from "../api/client";

const route = useRoute();
const router = useRouter();

const workspace = ref(null);
const editName = ref("");

const tasks = ref([]); // ★ 태스크 리스트

const loading = ref(false);
const saving = ref(false);
const deleting = ref(false);

const errorMessage = ref("");
const successMessage = ref("");

const fetchWorkspace = async () => {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  try {
    const id = route.params.id;
    const res = await api.get(`/workspaces/${id}`);
    // show: { id: ..., name: ... } 라고 가정
    workspace.value = res.data;
    editName.value = res.data.name;
  } catch (err) {
    const status = err.response?.status;
    const data = err.response?.data;
    if (status === 401 || status === 403) {
      router.push("/login");
      return;
    }
    if (status === 404) {
      errorMessage.value = "ワークスペースが見つかりませんでした。";
    } else {
      console.error("ワークスペース詳細取得に失敗しました:", err);
      errorMessage.value =
        data?.error || "ワークスペースの取得に失敗しました。";
    }
    workspace.value = null;
  } finally {
    loading.value = false;
  }
};

// ★ 이 워크스페이스의 태스크 목록을 가져온다
const fetchTasks = async () => {
  try {
    const workspaceId = route.params.id;
    const res = await api.get(`/workspaces/${workspaceId}/tasks`);
    // index: [{ id, title, status, category, assignee_id }, ...]
    tasks.value = res.data;
  } catch (err) {
    console.error("タスク一覧取得に失敗しました:", err);
    // 필요하면 task 전용 에러 메시지 따로 둘 수도 있음
  }
};

const onUpdate = async () => {
  errorMessage.value = "";
  successMessage.value = "";

  if (!editName.value.trim()) {
    errorMessage.value = "ワークスペース名は必須です。";
    return;
  }

  try {
    saving.value = true;
    const id = route.params.id;

    const res = await api.put(`/workspaces/${id}`, {
      workspace: {
        name: editName.value.trim(),
      },
    });

    successMessage.value =
      res.data.message || "ワークスペースを更新しました。";
    workspace.value = res.data.workspace;
    editName.value = res.data.workspace.name;
  } catch (err) {
    const data = err.response?.data;
    console.error("ワークスペース更新に失敗しました:", err);
    if (data?.details) {
      errorMessage.value = data.details.join(" / ");
    } else {
      errorMessage.value =
        data?.error || "ワークスペースの更新に失敗しました。";
    }
  } finally {
    saving.value = false;
  }
};

const onDelete = async () => {
  const ok = window.confirm(
    "本当にこのワークスペースを削除しますか？この操作は元に戻せません。"
  );
  if (!ok) return;

  try {
    deleting.value = true;
    const id = route.params.id;
    await api.delete(`/workspaces/${id}`);
    router.push("/workspaces");
  } catch (err) {
    const data = err.response?.data;
    console.error("ワークスペース削除に失敗しました:", err);
    errorMessage.value = data?.error || "ワークスペースの削除に失敗しました。";
  } finally {
    deleting.value = false;
  }
};

const goBack = () => {
  router.push("/workspaces");
};

// タスク詳細へ移動
const goToTask = (taskId) => {
  const workspaceId = route.params.id;
  router.push(`/workspaces/${workspaceId}/tasks/${taskId}`);
};

// タスク作成へ移動
const goToTaskCreate = () => {
  const workspaceId = route.params.id;
  router.push(`/workspaces/${workspaceId}/tasks/create`);
};

// 상태 라벨
const statusLabel = (status) => {
  if (status === "todo") return "未着手";
  if (status === "doing") return "進行中";
  if (status === "done") return "完了";
  return status || "";
};

onMounted(() => {
  fetchWorkspace();
  fetchTasks();
});

watch(
  () => route.params.id,
  () => {
    fetchWorkspace();
    fetchTasks();
  }
);
</script>

<style scoped>
.workspace-detail-page {
  min-height: 100vh;
  background: #f7f7f5;
  display: flex;
  justify-content: center;
  padding: 32px 16px;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
    sans-serif;
}

.workspace-shell {
  width: 100%;
  max-width: 800px;
}

.workspace-card {
  background: #ffffff;
  border-radius: 12px;
  padding: 20px 18px;
  border: 1px solid rgba(15, 23, 42, 0.08);
  box-shadow: 0 10px 30px rgba(15, 23, 42, 0.04);
  margin-bottom: 16px;
}

.card-header {
  margin-bottom: 12px;
}

.card-title {
  font-size: 18px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 4px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 10px;
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
  transition: border-color 0.15s ease, box-shadow 0.15s ease,
    background-color 0.15s ease;
}

.form-input:focus {
  border-color: #6366f1;
  background-color: #ffffff;
  box-shadow: 0 0 0 1px rgba(99, 102, 241, 0.4);
}

.form-error {
  font-size: 12px;
  color: #b91c1c;
  margin-bottom: 4px;
}

.form-success {
  font-size: 12px;
  color: #15803d;
  margin-bottom: 4px;
}

/* タスクセクション */
.workspace-subsections {
  margin-top: 16px;
}

.sub-card {
  background: #ffffff;
  border-radius: 12px;
  padding: 16px 18px;
  border: 1px solid rgba(15, 23, 42, 0.06);
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.03);
}

.sub-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.sub-action-button {
  border-radius: 999px;
  border: 1px solid #d1d5db;
  padding: 4px 10px;
  font-size: 12px;
  background: #ffffff;
  color: #374151;
  cursor: pointer;
}

.sub-action-button:hover {
  background: #f3f4f6;
}

.sub-title {
  font-size: 14px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 4px;
}

.sub-desc {
  font-size: 13px;
  color: #6b7280;
}

.task-list {
  list-style: none;
  padding: 0;
  margin: 4px 0 0;
}

.task-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 0;
  font-size: 13px;
  cursor: pointer;
}

.task-item + .task-item {
  border-top: 1px solid #e5e7eb;
}

.task-item:hover {
  background: #f9fafb;
}

.task-title {
  color: #111827;
}

.task-status {
  color: #6b7280;
}

/* 하단 버튼 */
.card-footer {
  margin-top: 20px;
}

.button-row {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
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