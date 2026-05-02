export interface MD_Account {
    user_id:                string,
    role:                   "admin" | "instructor" | "student";
    is_moderator:           boolean;
    gmail:                  string;
    full_name:              string;
    student_id:             string;
    course:                 string;
    profile_picture:        string;
}