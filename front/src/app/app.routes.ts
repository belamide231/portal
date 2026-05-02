import { Routes } from '@angular/router';
import { WelcomePage } from './pages/welcome-page/welcome-page';
import { LoginPage } from './pages/login-page/login-page';
import { RecoverAccountModal } from './modals/recover-account-modal/recover-account-modal';
import { ResetPasswordModal } from './modals/reset-password-modal/reset-password-modal';
import { SignUpModal } from './modals/sign-up-modal/sign-up-modal';
import { HomePage } from './pages/home-page/home-page';
import { DashboardPage } from './pages/dashboard-page/dashboard-page';
import { GroupPage } from './pages/group-page/group-page';
import { CreateGroupModal } from './modals/create-group-modal/create-group-modal';
import { EditGroupModal } from './modals/edit-group-modal/edit-group-modal';
import { InviteFromGroupModal } from './modals/invite-from-group-modal/invite-from-group-modal';
import { LeaveGroupModal } from './modals/leave-group-modal/leave-group-modal';
import { CreatePostModal } from './modals/create-post-modal/create-post-modal';
import { TaskPage } from './pages/task-page/task-page';
import { TasksModal } from './modals/tasks-modal/tasks-modal';
import { GradesModal } from './modals/grades-modal/grades-modal';
import { CreatePoolModal } from './modals/create-pool-modal/create-pool-modal';
import { GroupMembers } from './modals/group-members/group-members';
import { MembershipRequestsModal } from './modals/membership-requests-modal/membership-requests-modal';

export const routes: Routes = [
    { path: "welcome", component: WelcomePage },
    { path: "login", component: LoginPage, children: [
        { path: "recover", component: RecoverAccountModal },
        { path: "reset-password", component: ResetPasswordModal },
        { path: "sign-up", component: SignUpModal },
    ]},
    { path: "", component: HomePage, children: [
        { path: "recover", component: RecoverAccountModal },
        { path: "reset-password", component: ResetPasswordModal },
        { path: "create-group", component: CreateGroupModal },
        { path: "create-post", component: CreatePostModal },
        { path: "create-pool", component: CreatePoolModal },
    ]},
    { path: "dashboard", component: DashboardPage },
    { path: "group/:groupId", component: GroupPage, children: [
        { path: "edit-group", component: EditGroupModal },
        { path: "invite-from-group", component: InviteFromGroupModal },
        { path: "leave-group", component: LeaveGroupModal },
        { path: "create-post", component: CreatePostModal },
        { path: "tasks", component: TasksModal },
        { path: "grades", component: GradesModal },
        { path: "create-pool", component: CreatePoolModal },
        { path: "group-members", component: GroupMembers },
        { path: "membership-requests", component: MembershipRequestsModal },
    ]},
    { path: "task/:taskId", component: TaskPage },
];
