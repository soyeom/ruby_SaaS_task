<template lang="pug">
section.workspace-detail
  .container
    div(v-if="loading") 読み込み中…

    div(v-else-if="!workspace && errorMessage")
      p.message.error {{ errorMessage }}
      button.btn.btn-gray(@click="goBack") ← 戻る

    div(v-else)
      // ヘッダー
      .card.card-md
        input.workspace-title(
          type="text"
          v-model="editName"
          placeholder="ワークスペース名"
        )

      // タスク セクション
      .card.card-sm
        .section-header
          h2.section-title タスク
          button.btn.btn-primary(@click="goToTaskCreate") ＋

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
            button.btn.btn-primary.filter-button(@click="fetchTasks") 絞り込む
            button.btn.btn-gray.filter-clear(@click="resetFilters") クリア

        // タスクがない場合
        div.empty-msg(v-if="isTasksEmpty")
          | タスクはまだありません。

        // タスクがある場合
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

      // メンバー セクション
      .card.card-sm
        .section-header
          h2.section-title メンバー

        p.sub-desc(v-if="isMembersEmpty")
          | まだメンバーが登録されていません。login_id を指定して追加できます。

        div.member-chip-list(v-else)
          div.member-chip(
            v-for="m in members"
            :key="m.id"
          )
            span.member-chip-name {{ m.user ? m.user.login_id : m.login_id }}
            span.member-chip-role(
              v-if="m.role === 'owner'"
            ) オーナー
            span.member-chip-role(
              v-else
            ) メンバー
            button.member-chip-remove(
              v-if="m.role !== 'owner'"
              type="button"
              @click.stop="onRemoveMember(m)"
            ) ×
        form.member-form(@submit.prevent="onAddMember")
          .member-row
            input.member-input(
              type="text"
              v-model="newMemberLoginId"
              placeholder="追加したいユーザーの login_id"
            )
            select.member-select(v-model="newMemberRole")
              option(value="member") メンバー
              option(value="owner") オーナー
            button.btn.btn-gray.member-add-btn(type="submit" :disabled="memberSaving")
              span(v-if="memberSaving") 追加中…
              span(v-else) メンバー追加

          p.message.error(v-if="memberError") {{ memberError }}
          p.message.success(v-if="memberSuccess") {{ memberSuccess }}

      // タスク進捗 セクション
      .card.card-sm
        .section-header
          h2.section-title タスク進捗（担当者別）

        p.sub-desc(v-if="isProgressEmpty")
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

      .footer-actions
        button.btn.btn-primary(@click="onUpdate" :disabled="saving")
          span(v-if="saving") 更新中...
          span(v-else) ワークスペース名を更新

        button.btn.btn-danger(@click="onDelete" :disabled="deleting")
          span(v-if="deleting") 削除中...
          span(v-else) ワークスペースを削除

        button.btn.btn-gray(@click="goBack") 戻る
</template>
<script setup>
import { onMounted, ref, watch, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import api from "../api/client";

const route = useRoute();
const router = useRouter();

const workspace = ref(null);
const editName = ref("");

// 🔹 배열은 전부 ref([])로 초기화
const tasks = ref([]);
const progresses = ref([]);
const members = ref([]);

const newMemberLoginId = ref("");
const newMemberRole = ref("member");
const memberSaving = ref(false);
const memberError = ref("");
const memberSuccess = ref("");

const loading = ref(false);
const saving = ref(false);
const deleting = ref(false);

const errorMessage = ref("");
const successMessage = ref("");

// フィルター状態
const statusFilter = ref("all");
const assigneeFilter = ref("");
const categoryFilter = ref("");

// 🔹 空判定を computed にまとめる
const isTasksEmpty = computed(
  () => !Array.isArray(tasks.value) || tasks.value.length === 0
);

const isMembersEmpty = computed(
  () => !Array.isArray(members.value) || members.value.length === 0
);

const isProgressEmpty = computed(
  () => !Array.isArray(progresses.value) || progresses.value.length === 0
);

// 워크스페이스 정보 가져오기
const fetchWorkspace = async () => {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  try {
    const id = route.params.id;
    const res = await api.get(`/workspaces/${id}`);
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

const onAddMember = async () => {
  memberError.value = "";
  memberSuccess.value = "";

  if (!newMemberLoginId.value.trim()) {
    memberError.value = "login_id は必須です。";
    return;
  }

  try {
    memberSaving.value = true;

    const workspaceId = route.params.id;

    const res = await api.post(`/workspaces/${workspaceId}/members`, {
      login_id: newMemberLoginId.value.trim(),
      role: newMemberRole.value,
    });
    members.value.push(res.data.member);

    newMemberLoginId.value = "";
    newMemberRole.value = "member";
    memberSuccess.value = res.data.message || "メンバーを追加しました。";
  } catch (err) {
    const data = err.response?.data;
    if (data?.details) {
      memberError.value = data.details.join(" / ");
    } else {
      memberError.value =
        data?.error || "メンバーの追加に失敗しました。";
    }
  } finally {
    memberSaving.value = false;
  }
};

const onRemoveMember = async (member) => {
  memberError.value = "";
  memberSuccess.value = "";

  const name = member.user ? member.user.login_id : member.login_id;
  const ok = window.confirm(`${name} をメンバーから削除しますか？`);
  if (!ok) return;

  try {
    memberSaving.value = true;

    const workspaceId = route.params.id;
    await api.delete(`/workspaces/${workspaceId}/members/${member.id}`);

    members.value = members.value.filter((m) => m.id !== member.id);

    memberSuccess.value = "メンバーを削除しました。";
  } catch (err) {
    const data = err.response?.data;
    memberError.value =
      data?.error || "メンバーの削除に失敗しました。";
  } finally {
    memberSaving.value = false;
  }
};


// タスク一覧取得（フィルター反映）
const fetchTasks = async () => {
  try {
    const workspaceId = route.params.id;
    const params = {};

    if (statusFilter.value && statusFilter.value !== "all") {
      params.status = statusFilter.value;
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
    tasks.value = res.data || [];
  } catch (err) {
    console.error("タスク一覧取得に失敗しました:", err);
  }
};

// フィルターリセット
const resetFilters = () => {
  statusFilter.value = "all";
  assigneeFilter.value = "";
  categoryFilter.value = "";
  fetchTasks();
};

// 進捗データ取得
const fetchProgresses = async () => {
  try {
    const workspaceId = route.params.id;
    const res = await api.get(`/workspaces/${workspaceId}/task_progresses`);
    console.log("進捗データ:", res.data);
    progresses.value = res.data || [];
  } catch (err) {
    console.error("タスク進捗の取得に失敗しました:", err);
  }
};

// ワークスペース名更新
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
    errorMessage.value =
      data?.error || "ワークスペースの削除に失敗しました。";
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

// 状態ラベル変換
const statusLabel = (status) => {
  if (status === "todo") return "未着手";
  if (status === "doing") return "進行中";
  if (status === "done") return "完了";
  return status || "";
};

// 担当者名表示
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