<template lang="pug">
section.workspace-detail
  .container
    div(v-if="loading") 読み込み中…

    div(v-else-if="!workspace && errorMessage")
      p.error-text {{ errorMessage }}
      button.gray-button(@click="goBack") ← 戻る

    div(v-else)
      // ── 워크스페이스 헤더
      .header-card
        input.workspace-title(
          type="text"
          v-model="editName"
          placeholder="ワークスペース名"
        )

      // ── タスクセクション（フィルター＋一覧）
      .section-card
        .section-header
          h2 セクション: タスク
          button.add-task-btn(@click="goToTaskCreate") ＋ 新しいタスク

        // フィルター
        .filter-row
          .filter-field
            label.filter-label(for="statusFilter") ステータス
            select.filter-input#statusFilter(v-model="statusFilter")
              option(value="all") すべて
              option(value="todo") 未着手
              option(value="doing") 進行中
              option(value="done") 完了

          .filter-field
            label.filter-label(for="assigneeFilter") 担当者
            select.filter-input#assigneeFilter(v-model="assigneeFilter")
              option(value="") すべて
              option(
                v-for="m in members"
                :key="m.user ? m.user.id : m.id"
                :value="m.user ? m.user.id : m.id"
              )
                | {{ m.user ? m.user.login_id : m.login_id }}

          .filter-field
            label.filter-label(for="categoryFilter") カテゴリ
            input.filter-input#categoryFilter(
              type="text"
              v-model="categoryFilter"
              placeholder="カテゴリ名で絞り込み"
            )

          .filter-actions
            button.filter-button(@click="fetchTasks") 絞り込む
            button.filter-clear(@click="resetFilters") クリア

        // タスク一覧
        div(v-if="tasks.length === 0" class="empty-msg")
          | タスクはまだありません。

        ul.task-list(v-else)
          li.task-item(
            v-for="task in tasks"
            :key="task.id"
            @click="goToTask(task.id)"
          )
            .task-left
              span.title {{ task.title }}
              span.meta {{ statusLabel(task.status) }}
            .task-right
              span.assignee(v-if="task.assignee_id") 担当: {{ assigneeName(task.assignee_id) }}
              span.no-assignee(v-else) 未割当

      // ── タスク進捗セクション（担当者別）
      .section-card
        .section-header
          h2 タスク進捗（担当者別）

        p.sub-desc(v-if="progresses.length === 0")
          | まだ進捗データがありません。バッチ実行後に表示されます。

        ul.progress-list(v-else)
          li.progress-item(v-for="p in progresses" :key="p.user.id")
            .progress-left
              span.user-name {{ p.user.login_id }}
              span.progress-text {{ p.completed_tasks }} / {{ p.total_tasks }} 件
            .progress-right
              .progress-bar-outer
                .progress-bar-inner(:style="{ width: p.completion_rate + '%' }")
              span.progress-rate {{ p.completion_rate }}%

      // ── 하단 액션
      .footer-actions
        button.primary(@click="onUpdate" :disabled="saving")
          span(v-if="saving") 更新中...
          span(v-else) ワークスペース名を更新

        button.danger(@click="onDelete" :disabled="deleting")
          span(v-if="deleting") 削除中...
          span(v-else) ワークスペースを削除

        button.gray(@click="goBack") 戻る
</template>

<script setup>
import { onMounted, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import api from "../api/client";

const route = useRoute();
const router = useRouter();

const workspace = ref(null);
const editName = ref("");

const tasks = ref([]);
const progresses = ref([]);
const members = ref([]);

const loading = ref(false);
const saving = ref(false);
const deleting = ref(false);

const errorMessage = ref("");
const successMessage = ref("");

// 필터 상태
const statusFilter = ref("all");
const assigneeFilter = ref("");
const categoryFilter = ref("");

// 워크스페이스 정보 가져오기 (이름 + 멤버)
const fetchWorkspace = async () => {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  try {
    const id = route.params.id;
    const res = await api.get(`/workspaces/${id}`);
    // show 응답에 { id, name, members: [...] } 있다고 가정
    workspace.value = res.data;
    editName.value = res.data.name;
    members.value = res.data.members || [];
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

// 태스크 목록 가져오기 (필터 반영)
const fetchTasks = async () => {
  try {
    const workspaceId = route.params.id;
    const params = {};

    if (statusFilter.value && statusFilter.value !== "all") {
      params.status = statusFilter.value; // "todo"/"doing"/"done"
    }
    if (assigneeFilter.value) {
      params.assignee_id = assigneeFilter.value;
    }
    if (categoryFilter.value.trim()) {
      params.category = categoryFilter.value.trim();
    }

    const res = await api.get(`/workspaces/${workspaceId}/tasks`, {
      params,
    });
    tasks.value = res.data;
  } catch (err) {
    console.error("タスク一覧取得に失敗しました:", err);
  }
};

// 필터 리셋
const resetFilters = () => {
  statusFilter.value = "all";
  assigneeFilter.value = "";
  categoryFilter.value = "";
  fetchTasks();
};

// 진행률 데이터 가져오기
const fetchProgresses = async () => {
  try {
    const workspaceId = route.params.id;
    const res = await api.get(`/workspaces/${workspaceId}/task_progresses`);
    progresses.value = res.data;
  } catch (err) {
    console.error("タスク進捗の取得に失敗しました:", err);
  }
};

// 워크스페이스 이름 업데이트
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

const goToTask = (taskId) => {
  const workspaceId = route.params.id;
  router.push(`/workspaces/${workspaceId}/tasks/${taskId}`);
};

const goToTaskCreate = () => {
  const workspaceId = route.params.id;
  router.push(`/workspaces/${workspaceId}/tasks/create`);
};

// 상태 라벨 변환
const statusLabel = (status) => {
  if (status === "todo") return "未着手";
  if (status === "doing") return "進行中";
  if (status === "done") return "完了";
  return status || "";
};

// 담당자 이름 표시
const assigneeName = (assigneeId) => {
  const member =
    workspace.value?.members?.find((m) => m.user?.id === assigneeId) ||
    members.value.find((m) => m.user?.id === assigneeId);
  if (!member) return "不明";
  return member.user ? member.user.login_id : member.login_id;
};

onMounted(() => {
  fetchWorkspace();
  fetchTasks();
  fetchProgresses();
});

watch(
  () => route.params.id,
  () => {
    fetchWorkspace();
    fetchTasks();
    fetchProgresses();
  }
);
</script>

<style scoped>
.workspace-detail {
  background: #f8f9fb;
  min-height: 100vh;
  padding: 40px 0;
  display: flex;
  justify-content: center;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.container {
  width: 100%;
  max-width: 760px;
}

/* 헤더 카드 */
.header-card {
  background: white;
  padding: 24px;
  border-radius: 14px;
  box-shadow: 0 6px 20px rgba(0,0,0,0.04);
  margin-bottom: 20px;
}

.workspace-title {
  font-size: 20px;
  font-weight: 600;
  border: none;
  outline: none;
  width: 100%;
  padding: 6px 0;
  margin-bottom: 6px;
}

.sub-info {
  font-size: 12px;
  color: #888;
}

/* 섹션 카드 */
.section-card {
  background: white;
  padding: 20px;
  border-radius: 14px;
  box-shadow: 0 6px 20px rgba(0,0,0,0.04);
  margin-bottom: 20px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.add-task-btn {
  padding: 6px 12px;
  font-size: 13px;
  border-radius: 999px;
  border: none;
  background: #4f46e5;
  color: white;
  cursor: pointer;
}

.add-task-btn:hover {
  background: #4338ca;
}

.sub-desc {
  font-size: 13px;
  color: #6b7280;
}

/* 필터 영역 */
.filter-row {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr)) auto;
  gap: 8px;
  margin-bottom: 10px;
  align-items: flex-end;
}

.filter-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.filter-label {
  font-size: 12px;
  color: #6b7280;
}

.filter-input {
  padding: 6px 8px;
  border-radius: 10px;
  border: 1px solid #d1d5db;
  font-size: 13px;
  background-color: #f9fafb;
  outline: none;
}

.filter-input:focus {
  border-color: #6366f1;
  background-color: #ffffff;
  box-shadow: 0 0 0 1px rgba(99, 102, 241, 0.4);
}

.filter-actions {
  display: flex;
  gap: 6px;
}

.filter-button,
.filter-clear {
  border-radius: 999px;
  border: 1px solid #d1d5db;
  padding: 6px 10px;
  font-size: 12px;
  background: #ffffff;
  cursor: pointer;
}

.filter-button {
  background: #111827;
  color: white;
  border-color: #111827;
}

.filter-clear {
  color: #374151;
}

.empty-msg {
  font-size: 13px;
  color: #6b7280;
}

/* 태스크 리스트 */
.task-list {
  list-style: none;
  padding: 0;
  margin: 8px 0 0;
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

.task-left .title {
  font-weight: 500;
  color: #111827;
}

.task-left .meta {
  font-size: 12px;
  color: #6b7280;
  display: block;
}

.assignee {
  font-size: 12px;
  background: #eef2ff;
  padding: 4px 8px;
  border-radius: 999px;
  color: #3730a3;
}

.no-assignee {
  font-size: 12px;
  color: #aaa;
}

/* 진행률 리스트 */
.progress-list {
  list-style: none;
  padding: 0;
  margin: 8px 0 0;
}

.progress-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 0;
  font-size: 13px;
}

.progress-item + .progress-item {
  border-top: 1px solid #e5e7eb;
}

.progress-left .user-name {
  font-weight: 500;
  color: #111827;
}

.progress-left .progress-text {
  display: block;
  font-size: 12px;
  color: #6b7280;
}

.progress-right {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 140px;
}

.progress-bar-outer {
  width: 100px;
  height: 6px;
  border-radius: 999px;
  background: #e5e7eb;
  overflow: hidden;
}

.progress-bar-inner {
  height: 100%;
  background: #4f46e5;
  border-radius: 999px;
}

.progress-rate {
  font-size: 12px;
  color: #4b5563;
}

/* 하단 버튼 */
.footer-actions {
  margin-top: 8px;
  display: flex;
  gap: 10px;
}

.primary,
.danger,
.gray {
  border-radius: 999px;
  padding: 8px 14px;
  font-size: 14px;
  cursor: pointer;
  border: none;
}

.primary {
  background: #111827;
  color: white;
}

.danger {
  background: #ef4444;
  color: white;
}

.gray {
  background: #fff;
  border: 1px solid #ddd;
  color: #374151;
}

.primary:disabled,
.danger:disabled {
  opacity: 0.6;
  cursor: default;
}

.error-text {
  color: #b91c1c;
  font-size: 14px;
}
</style>