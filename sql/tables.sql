-- CONNECTION: jdbc:mysql://127.0.0.1:3306/cec_portal?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=Asia/Manila

DROP DATABASE IF EXISTS cec_portal;
CREATE DATABASE IF NOT EXISTS cec_portal;
USE cec_portal;

SET FOREIGN_KEY_CHECKS = 0;
SET FOREIGN_KEY_CHECKS = 1;

-- PORTAL 
DROP TABLE IF EXISTS tbl_portal_policy;
CREATE TABLE IF NOT EXISTS tbl_portal_policy (
	policy_id ENUM("1") NOT NULL DEFAULT "1" UNIQUE,
	post_policy ENUM("public", "moderated"),
	group_creation_policy ENUM("everyone", "staff_only") DEFAULT "staff_only" COMMENT "everyone: all role; staff_only: staff/instructor/admin;"
);

INSERT INTO tbl_portal_policy(policy_id, post_policy, group_creation_policy)
SELECT "1", "moderated", "staff_only";

-- USERS
DROP TABLE IF EXISTS tbl_users_account;
CREATE TABLE IF NOT EXISTS tbl_users_account (
	user_id VARCHAR(99) PRIMARY KEY DEFAULT (UUID()),
	username VARCHAR(99) NOT NULL UNIQUE,
	password VARCHAR(256) NOT NULL,
	ROLE ENUM("admin", "instructor", "student") NOT NULL,
	is_moderator BOOLEAN DEFAULT FALSE,
	gmail VARCHAR(99),
	fail_attempt INT DEFAULT 0,
	lock_expiration DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_users_profile;
CREATE TABLE IF NOT EXISTS tbl_users_profile (
	user_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id) 
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	full_name VARCHAR(99) NOT NULL DEFAULT "Martin Garix", 
	student_id VARCHAR(99) NOT NULL DEFAULT "00000000", 
	course ENUM("BSCRIM", "BSED", "BSDC", "BSHM", "BSIT", "BSTM", "") NOT NULL,
	profile_picture VARCHAR(9999) NOT NULL DEFAULT ""
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_users_connection;
CREATE TABLE IF NOT EXISTS tbl_users_connection (
	user_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	connection_id VARCHAR(99)
);

DROP TABLE IF EXISTS tbl_invited_gmails;
CREATE TABLE IF NOT EXISTS tbl_invited_gmails (
	gmail VARCHAR(99) NOT NULL UNIQUE,
	sender_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (sender_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	sent_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	course VARCHAR(20) NOT NULL,
	ROLE VARCHAR(20) NOT NULL,
	identifier VARCHAR(99) NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_users_update;
CREATE TABLE IF NOT EXISTS tbl_users_update (
	user_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id)
	 		ON DELETE CASCADE
	 		ON UPDATE CASCADE,
	update_type VARCHAR(99) NOT NULL,
	update_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	code VARCHAR(99) NOT NULL
) ENGINE = Innodb;

-- GROUP
DROP TABLE IF EXISTS tbl_groups;
CREATE TABLE IF NOT EXISTS tbl_groups (
	group_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	group_created_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	group_type ENUM("group", "class") NOT NULL,
	join_policy ENUM("open", "close", "request_join") NOT NULL DEFAULT "close",
	post_policy ENUM("public", "moderated", "staff_only", "staff_moderated", "restricted") DEFAULT "restricted" COMMENT "public: everyone; moderated: user req/admin apprv; staff_only: mod/admin; staff_moderated: mod req/admin apprv; restricted: admin only",
	author_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (author_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	group_name VARCHAR(99) NOT NULL,
	group_description VARCHAR(999) NOT NULL DEFAULT ""
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_group_members;
CREATE TABLE IF NOT EXISTS tbl_group_members (
	membership_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	group_id INT NOT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	member_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (member_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	join_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	referrer_id VARCHAR(99) NULL DEFAULT NULL,
		FOREIGN KEY (referrer_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	group_role ENUM("group_author", "group_moderator", "group_member") NOT NULL DEFAULT "group_member"
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_group_membership_requests;
CREATE TABLE IF NOT EXISTS tbl_group_membership_requests (
	membership_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	group_id INT NOT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	candidate_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (candidate_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	referrer_id VARCHAR(99) NULL DEFAULT NULL,
		FOREIGN KEY (candidate_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	origin ENUM("invited", "request_join") NOT NULL,
	origin_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
) ENGINE = Innodb;

SET FOREIGN_KEY_CHECKS = 1;

-- POST
DROP TABLE IF EXISTS tbl_posts;
CREATE TABLE IF NOT EXISTS tbl_posts (
	post_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	group_id INT NULL DEFAULT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id),
	post_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	author_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (author_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	post_text VARCHAR(7999) NOT NULL DEFAULT "",
	is_important BOOLEAN NOT NULL DEFAULT FALSE,
	like_count INT NOT NULL DEFAULT 0,
	share_count INT NOT NULL DEFAULT 0,
	comment_count INT NOT NULL DEFAULT 0,
	post_status ENUM("pending", "posted") DEFAULT "pending",
	reviewer_id VARCHAR(99) NULL DEFAULT NULL,
		FOREIGN KEY (reviewer_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_post_files;
CREATE TABLE IF NOT EXISTS tbl_post_files (
	post_id INT NOT NULL,
		FOREIGN KEY (post_id) REFERENCES tbl_posts(post_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	file_name VARCHAR(999) NOT NULL,
	extension VARCHAR(20) NOT NULL,
	full_path VARCHAR(999) NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_post_interactions;
CREATE TABLE IF NOT EXISTS tbl_post_interactions (
	post_interaction_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	post_id INT NOT NULL,
		FOREIGN KEY (post_id) REFERENCES tbl_posts(post_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	interaction_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	user_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	interaction_type ENUM("liked", "commented") NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_post_comments;
CREATE TABLE IF NOT EXISTS tbl_post_comments (
	comment_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	post_id INT NOT NULL,
		FOREIGN KEY (post_id) REFERENCES tbl_posts(post_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	comment_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	author_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (author_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	comment_text VARCHAR(7999),
	like_count INT NOT NULL DEFAULT 0,
	comment_status ENUM("pending", "posted"),
	reviewer_id VARCHAR(99) NULL DEFAULT NULL,
		FOREIGN KEY (reviewer_id) REFERENCES tbl_users_account(user_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_post_comment_files;
CREATE TABLE IF NOT EXISTS tbl_post_comment_files (
	comment_id INT NOT NULL,
		FOREIGN KEY (comment_id) REFERENCES tbl_post_comments(comment_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	file_name VARCHAR(999) NOT NULL,
	extension VARCHAR(20) NOT NULL,
	full_path VARCHAR(999) NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_comment_interactions;
CREATE TABLE IF NOT EXISTS tbl_comment_interactions (
	comment_interaction_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	comment_id INT NOT NULL,
		FOREIGN KEY (comment_id) REFERENCES tbl_post_comments(comment_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	interaction_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	user_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	interaction_type ENUM("liked", "commented") NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_post_comment_replies;
CREATE TABLE IF NOT EXISTS tbl_post_comment_replies (
	reply_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	comment_id INT NOT NULL,
		FOREIGN KEY (comment_id) REFERENCES tbl_post_comments(comment_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	reply_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	author_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (author_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	reply_text VARCHAR(7999),
	like_count INT NOT NULL DEFAULT 0
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_post_comment_reply_files;
CREATE TABLE IF NOT EXISTS tbl_post_comment_reply_files (
	reply_id INT NOT NULL,
		FOREIGN KEY (reply_id) REFERENCES tbl_post_comment_replies(reply_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	file_name VARCHAR(999) NOT NULL,
	extension VARCHAR(20) NOT NULL,
	full_path VARCHAR(999) NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_comment_reply_interactions;
CREATE TABLE IF NOT EXISTS tbl_comment_reply_interactions (
	reply_interaction_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	reply_id INT NOT NULL,
		FOREIGN KEY (reply_id) REFERENCES tbl_post_comment_replies(reply_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	interaction_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	user_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	interaction_type ENUM("liked", "commented") NOT NULL
) ENGINE = Innodb;

-- POOL
DROP TABLE IF EXISTS tbl_pool;
CREATE TABLE IF NOT EXISTS tbl_pool (
	pool_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	pool_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	group_id INT NOT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	author_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (author_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_pool_options;
CREATE TABLE IF NOT EXISTS tbl_pool_options (
	option_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	pool_id INT NOT NULL,
		FOREIGN KEY (pool_id) REFERENCES tbl_pool(pool_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	option_text VARCHAR(7999) NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_pool_choice_files;
CREATE TABLE IF NOT EXISTS tbl_pool_choice_files (
	option_id INT NOT NULL,
		FOREIGN KEY (option_id) REFERENCES tbl_pool_options(option_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	file_name VARCHAR(999) NOT NULL,
	extension VARCHAR(20) NOT NULL,
	full_path VARCHAR(999) NOT NULL	
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_pool_votes;
CREATE TABLE IF NOT EXISTS tbl_pool_votes (
	option_id INT NOT NULL,
		FOREIGN KEY (option_id) REFERENCES tbl_pool_options(option_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	voter_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (voter_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
) ENGINE = Innodb;


-- CHAT
DROP TABLE IF EXISTS tbl_chat;
CREATE TABLE IF NOT EXISTS tbl_chat (
	chat_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	chat_type ENUM("pair", "group") NOT NULL,
	group_id INT NOT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	latest_stamp DATETIME NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_chat_read_states;
CREATE TABLE IF NOT EXISTS tbl_chat_read_states (
	chat_id INT NOT NULL,
		FOREIGN KEY (chat_id) REFERENCES tbl_chat(chat_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	user_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	delivered_stamp DATETIME NULL,
	seen_stamp DATETIME NULL,
	deleted_stamp DATETIME NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_chat_messages;
CREATE TABLE IF NOT EXISTS tbl_chat_messages (
	message_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	message_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	chat_id INT NOT NULL,
		FOREIGN KEY (chat_id) REFERENCES tbl_chat(chat_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	sender_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (sender_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	message_text VARCHAR(7999),
	to_message_id INT NULL,
		FOREIGN KEY (to_message_id) REFERENCES tbl_chat_messages(message_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_chat_message_files;
CREATE TABLE IF NOT EXISTS tbl_chat_message_files (
	message_id INT NOT NULL,
		FOREIGN KEY (message_id) REFERENCES tbl_chat_messages(message_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	file_name VARCHAR(999) NOT NULL,
	extension VARCHAR(20) NOT NULL,
	full_path VARCHAR(999) NOT NULL
) ENGINE = Innodb;

-- GROUP/TASK
DROP TABLE IF EXISTS tbl_task_category;
CREATE TABLE IF NOT EXISTS tbl_task_category (
	group_id INT NOT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	category_name VARCHAR(99) NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_tasks;
CREATE TABLE IF NOT EXISTS tbl_tasks (
	task_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	group_id INT NOT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	task_status ENUM("draft", "scheduled", "published", "closed") NOT NULL DEFAULT "draft",
	period ENUM("prelim", "mid-term", "semi-finals", "finals") NOT NULL,
	category_name VARCHAR(99) NOT NULL,
	created_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	due_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	author_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (author_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	task_name VARCHAR(99) NOT NULL,
	task_no INT NOT NULL,
	with_points BOOLEAN NOT NULL,
	with_timer BOOLEAN NOT NULL
) ENGINE = Innodb;



DROP TABLE IF EXISTS tbl_task_questions;
CREATE TABLE IF NOT EXISTS tbl_task_questions (
	question_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	task_id INT NOT NULL,
		FOREIGN KEY (task_id) REFERENCES tbl_tasks(task_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	duration INT NOT NULL DEFAULT 0,
	points INT NOT NULL DEFAULT 0,
	question_type ENUM("true_or_false", "multiple_choices", "identification") NOT NULL,
	question_text VARCHAR(7999),
	answer VARCHAR(7999)
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_task_question_file;
CREATE TABLE IF NOT EXISTS tbl_task_question_file (
	question_id INT NOT NULL,
		FOREIGN KEY (question_id) REFERENCES tbl_task_questions(question_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	file_name VARCHAR(999) NOT NULL,
	extension VARCHAR(20) NOT NULL,
	full_path VARCHAR(999) NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_task_question_choices;
CREATE TABLE IF NOT EXISTS tbl_task_question_choices (
	choice_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	question_id INT NOT NULL,
		FOREIGN KEY (question_id) REFERENCES tbl_task_questions(question_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	choice_text VARCHAR(7999)
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_task_question_response;
CREATE TABLE IF NOT EXISTS tbl_task_question_response (
	question_id INT NOT NULL,
		FOREIGN KEY (question_id) REFERENCES tbl_task_questions(question_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	respondent_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (respondent_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	response_text VARCHAR(7999)
) ENGINE = Innodb;

-- GROUP/GRADE
DROP TABLE IF EXISTS tbl_grades;
CREATE TABLE IF NOT EXISTS tbl_grades (
	group_id INT NOT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	period ENUM("prelim", "mid-term", "semi-finals", "finals") NOT NULL,
	completion DECIMAL NOT NULL DEFAULT 0,
	gpa DECIMAL NOT NULL DEFAULT 0
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_grade_component;
CREATE TABLE IF NOT EXISTS tbl_grade_component (
	group_id INT NOT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	period ENUM("prelim", "mid-term", "semi-finals", "finals") NOT NULL,
	component_name VARCHAR(99) NOT NULL,
	weight_percentage INT NOT NULL DEFAULT 0
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_grade_academic_records;
CREATE TABLE IF NOT EXISTS tbl_grade_academic_records (
	assessment_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	group_id INT NOT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	period ENUM("prelim", "mid-term", "semi-finals", "finals") NOT NULL,
	component_name VARCHAR(99) NOT NULL,
	assessment_no VARCHAR(99) NOT NULL,
	max_score INT NOT NULL DEFAULT 0,
	is_synced BOOLEAN DEFAULT FALSE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_grade_student_records;
CREATE TABLE IF NOT EXISTS tbl_grade_student_records (
	score_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	assessment_id INT NOT NULL,
		FOREIGN KEY (assessment_id) REFERENCES tbl_grade_academic_records(assessment_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	student_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (student_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	score INT NOT NULL DEFAULT 0
) ENGINE = Innodb;

-- USERS/NOTIFICATION
DROP TABLE IF EXISTS tbl_users_notification;
CREATE TABLE IF NOT EXISTS tbl_users_notification (
	notification_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	notification_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	sender_id VARCHAR(99) NULL DEFAULT NULL,
		FOREIGN KEY (sender_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE, 
	recipient_id VARCHAR(99) NULL DEFAULT NULL,
		FOREIGN KEY (recipient_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	notification_text VARCHAR(99) NOT NULL,
	notification_type ENUM(
		"CREATED_GROUP",
		"PENDING_GROUP_INVITATION",
		"ACCEPTED_GROUP_INVITATION",
		"REQUESTING_GROUP_JOIN",
		"ACCEPTED_GROUP_JOIN",
		"KICKED_YOU",
		"COMMENTED_POST",
		"REPLIED_POST",
		"LIKED_POST",
		"LIKED_COMMENT",
		"LIKED_REPLY",
		"POST_APPROVE",
		"POSTED_TASK", 
		"UPDATED_ROLE"
	) NOT NULL,
	target_url VARCHAR(7999) NOT NULL,
	is_viewed BOOLEAN NOT NULL DEFAULT FALSE,
	is_opened BOOLEAN NOT NULL DEFAULT FALSE,
	group_id INT NULL DEFAULT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	membership_id INT NULL DEFAULT NULL,
		FOREIGN KEY (membership_id) REFERENCES tbl_group_membership_requests(membership_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	post_id INT NULL DEFAULT NULL,
		FOREIGN KEY (membership_id) REFERENCES tbl_group_membership_requests(membership_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	comment_id INT NULL DEFAULT NULL,
		FOREIGN KEY (comment_id) REFERENCES tbl_post_comments(comment_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	reply_id INT NULL DEFAULT NULL,
		FOREIGN KEY (reply_id) REFERENCES tbl_post_comment_replies(reply_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	post_interaction_id INT NULL DEFAULT NULL,
		FOREIGN KEY (post_interaction_id) REFERENCES tbl_post_interactions(post_interaction_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	comment_interaction_id INT NULL DEFAULT NULL,
		FOREIGN KEY (comment_interaction_id) REFERENCES tbl_comment_interactions(comment_interaction_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	reply_interaction_id INT NULL DEFAULT NULL,
		FOREIGN KEY (reply_interaction_id) REFERENCES tbl_comment_reply_interactions(reply_interaction_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	task_id INT NULL DEFAULT NULL,
		FOREIGN KEY (task_id) REFERENCES tbl_tasks(task_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_users_notification_muted;
CREATE TABLE IF NOT EXISTS tbl_users_notification_muted (
	group_id INT NULL DEFAULT NULL,
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	membership_id INT NULL DEFAULT NULL,
		FOREIGN KEY (membership_id) REFERENCES tbl_group_membership_requests(membership_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	post_id INT NULL DEFAULT NULL,
		FOREIGN KEY (membership_id) REFERENCES tbl_group_membership_requests(membership_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	comment_id INT NULL DEFAULT NULL,
		FOREIGN KEY (comment_id) REFERENCES tbl_post_comments(comment_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	reply_id INT NULL DEFAULT NULL,
		FOREIGN KEY (reply_id) REFERENCES tbl_post_comment_replies(reply_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	post_interaction_id INT NULL DEFAULT NULL,
		FOREIGN KEY (post_interaction_id) REFERENCES tbl_post_interactions(post_interaction_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	comment_interaction_id INT NULL DEFAULT NULL,
		FOREIGN KEY (comment_interaction_id) REFERENCES tbl_comment_interactions(comment_interaction_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	reply_interaction_id INT NULL DEFAULT NULL,
		FOREIGN KEY (reply_interaction_id) REFERENCES tbl_comment_reply_interactions(reply_interaction_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE
);

-- INITIAL
DESCRIBE tbl_users_account;
DESCRIBE tbl_users_profile;

SELECT * FROM tbl_users_account;
SELECT * FROM tbl_users_profile;

DELETE FROM tbl_users_account;
DELETE FROM tbl_users_profile;

SET @username = "student";
SET @password = "$2a$11$eyXlppBlvJwv2fYtWRGa5eV3eCgjVTTZBmKyNs3joGX/b8uV13vPq";
SET @role = "student";
SET @gmail = "student";

INSERT INTO tbl_users_account(username, password, role, gmail)
WITH RECURSIVE recursion AS (
	SELECT 1 n
	UNION ALL
	SELECT n + 1
	FROM recursion
	WHERE n < 10
)
SELECT 
	CONCAT(@username, n) username,
	@password password,
	@role role,
	CONCAT(@gmail, n, "@gmail.com") gmail
FROM recursion;

SET @username = "admin";
SET @password = "$2a$11$eyXlppBlvJwv2fYtWRGa5eV3eCgjVTTZBmKyNs3joGX/b8uV13vPq";
SET @role = "admin";
SET @gmail = "admin";

INSERT INTO tbl_users_account(username, password, role, gmail)
SELECT
	@username username,
	@password password,
	@role role,
	CONCAT(@gmail, "@gmail.com") gmail;

INSERT INTO tbl_users_profile(user_id, full_name, course)
SELECT 
user_id, 
gmail, 
CASE
	WHEN role = "admin" THEN ""
	ELSE (
		SELECT ELT(FLOOR(RAND() * 6) + 1, 'BSCRIM', 'BSED', 'BSDC', 'BSHM', 'BSIT', 'BSTM')
	)
END course
FROM tbl_users_account;

UPDATE tbl_users_account SET is_moderator = TRUE WHERE username IN ("student6", "student7");

INSERT tbl_users_connection(user_id, connection_id)
SELECT 
	user_id, UUID()
FROM tbl_users_account;

INSERT INTO tbl_users_connection(user_id, connection_id)
SELECT user_id, UUID() FROM tbl_users_account ORDER BY RAND() LIMIT 5;
INSERT INTO tbl_users_connection(user_id, connection_id)
SELECT user_id, UUID() FROM tbl_users_account ORDER BY RAND() LIMIT 5;
INSERT INTO tbl_users_connection(user_id, connection_id)
SELECT user_id, UUID() FROM tbl_users_account ORDER BY RAND() LIMIT 5;
INSERT INTO tbl_users_connection(user_id, connection_id)
SELECT user_id, UUID() FROM tbl_users_account ORDER BY RAND() LIMIT 5;
INSERT INTO tbl_users_connection(user_id, connection_id)
SELECT user_id, UUID() FROM tbl_users_account ORDER BY RAND() LIMIT 5;