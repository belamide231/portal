-- CONNECTION: jdbc:mysql://127.0.0.1:3306/cec_portal?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=Asia/Manila

DROP DATABASE IF EXISTS cec_portal;
CREATE DATABASE IF NOT EXISTS cec_portal;
USE cec_portal;

SET FOREIGN_KEY_CHECKS = 0;
SET FOREIGN_KEY_CHECKS = 1;

-- PORTAL 
DROP TABLE IF EXISTS tbl_portal_policy;
CREATE TABLE IF NOT EXISTS tbl_portal_policy (
	policy_id ENUM('1') NOT NULL DEFAULT '1' UNIQUE,
	post_policy ENUM('public', 'moderated', 'restricted') NOT NULL DEFAULT 'moderated',
	comment_policy ENUM('public', 'moderated', 'restricted') NOT NULL DEFAULT 'moderated',
	group_creation_policy ENUM('everyone', 'staff_only') NOT NULL DEFAULT 'staff_only'
);

INSERT INTO tbl_portal_policy(policy_id, post_policy, comment_policy, group_creation_policy)
SELECT '1', 'moderated', 'staff_only';

-- USERS
DROP TABLE IF EXISTS tbl_users_account;
CREATE TABLE IF NOT EXISTS tbl_users_account (
	user_id VARCHAR(99) PRIMARY KEY DEFAULT (UUID()),
		INDEX index_user_id (user_id),
	username VARCHAR(99) NOT NULL UNIQUE,
	password VARCHAR(256) NOT NULL,
	ROLE ENUM('admin', 'instructor', 'student') NOT NULL,
	is_moderator BOOLEAN DEFAULT FALSE,
	gmail VARCHAR(99),
	fail_attempt INT DEFAULT 0,
	lock_expiration DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_users_profile;
CREATE TABLE IF NOT EXISTS tbl_users_profile (
	user_id VARCHAR(99) NOT NULL,
		INDEX index_user_id (user_id),
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id) 
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	full_name VARCHAR(99) NOT NULL DEFAULT 'Martin Garix', 
	student_id VARCHAR(99) NOT NULL DEFAULT '00000000', 
	course ENUM('BSCRIM', 'BSED', 'BSDC', 'BSHM', 'BSIT', 'BSTM', '') NOT NULL,
	profile_picture VARCHAR(9999) NOT NULL DEFAULT ''
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_users_connection;
CREATE TABLE IF NOT EXISTS tbl_users_connection (
	user_id VARCHAR(99) NOT NULL,
		INDEX index_user_id (user_id),
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
		INDEX index_group_id (group_id),
	group_created_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	group_type ENUM('group', 'class') NOT NULL,
	join_policy ENUM('open', 'close', 'request_join') NOT NULL DEFAULT 'close',
	post_policy ENUM('public', 'moderated', 'restricted') DEFAULT 'moderated',
	comment_policy ENUM('public', 'moderated', 'restricted') DEFAULT 'moderated',
	author_id VARCHAR(99) NOT NULL,
		FOREIGN KEY (author_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	group_name VARCHAR(99) NOT NULL,
	group_description VARCHAR(999) NOT NULL DEFAULT ''
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_group_members;
CREATE TABLE IF NOT EXISTS tbl_group_members (
	membership_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
		INDEX index_membership_id (membership_id),
	group_id INT NOT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE 
			ON UPDATE CASCADE,
	member_id VARCHAR(99) NOT NULL,
		INDEX index_member_id  (member_id),
		FOREIGN KEY (member_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	join_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	referrer_id VARCHAR(99) NULL DEFAULT NULL,
		INDEX index_referrer_id (referrer_id),
		FOREIGN KEY (referrer_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	group_role ENUM('group_author', 'group_moderator', 'group_member') NOT NULL DEFAULT 'group_member',
	is_group_moderator BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_group_membership_requests;
CREATE TABLE IF NOT EXISTS tbl_group_membership_requests (
	membership_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	group_id INT NOT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE 
			ON UPDATE CASCADE,
	candidate_id VARCHAR(99) NOT NULL,
		INDEX index_candidate_id (candidate_id),
		FOREIGN KEY (candidate_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	referrer_id VARCHAR(99) NULL DEFAULT NULL,
		INDEX index_referrer_id (referrer_id),
		FOREIGN KEY (referrer_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	origin ENUM('invited', 'request_join') NOT NULL,
	origin_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
) ENGINE = Innodb;

-- POST
DROP TABLE IF EXISTS tbl_posts;
CREATE TABLE IF NOT EXISTS tbl_posts (
	post_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
		INDEX index_post_id (post_id),
	group_id INT NULL DEFAULT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	post_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	author_id VARCHAR(99) NOT NULL,
		INDEX index_author_id (author_id),
		FOREIGN KEY (author_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	post_text VARCHAR(7999) NOT NULL DEFAULT '',
	is_important BOOLEAN NOT NULL DEFAULT FALSE,
	like_count INT NOT NULL DEFAULT 0,
	share_count INT NOT NULL DEFAULT 0,
	comment_count INT NOT NULL DEFAULT 0,
	post_status ENUM('pending', 'posted') DEFAULT 'pending',
	reviewer_id VARCHAR(99) NULL DEFAULT NULL,
		INDEX index_reviewer_id (reviewer_id),
		FOREIGN KEY (reviewer_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_post_files;
CREATE TABLE IF NOT EXISTS tbl_post_files (
	post_id INT NOT NULL,
		INDEX index_post_id (post_id),
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
		INDEX index_post_id (post_id),
		FOREIGN KEY (post_id) REFERENCES tbl_posts(post_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	interaction_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	user_id VARCHAR(99) NOT NULL,
		INDEX index_user_id (user_id),
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	interaction_type ENUM('liked', 'commented') NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_post_tags;
CREATE TABLE IF NOT EXISTS tbl_post_tags (
	tag_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
		INDEX index_tag_id (tag_id),
	post_id INT NOT NULL,
		INDEX index_post_id (post_id),
		FOREIGN KEY (post_id) REFERENCES tbl_posts(post_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	user_id VARCHAR(99) NOT NULL,
		INDEX index_user_id (user_id),
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_post_comments;
CREATE TABLE IF NOT EXISTS tbl_post_comments (
	comment_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
		INDEX index_comment_id (comment_id),
	parent_comment_id INT NULL DEFAULT NULL,
		INDEX index_parent_comment_id (parent_comment_id),
		FOREIGN KEY (parent_comment_id) REFERENCES tbl_post_comments(comment_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	post_id INT NOT NULL,
		INDEX index_post_id (post_id),
		FOREIGN KEY (post_id) REFERENCES tbl_posts(post_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	group_id INT NULL DEFAULT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	comment_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	author_id VARCHAR(99) NOT NULL,
		INDEX index_author_id (author_id),
		FOREIGN KEY (author_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	comment_text VARCHAR(7999),
	like_count INT NOT NULL DEFAULT 0,
	comment_status ENUM('pending', 'posted') NOT NULL,
	reviewer_id VARCHAR(99) NULL DEFAULT NULL,
		INDEX index_reviewer_id (reviewer_id),
		FOREIGN KEY (reviewer_id) REFERENCES tbl_users_account(user_id) 
			ON DELETE CASCADE 
			ON UPDATE CASCADE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_post_comment_files;
CREATE TABLE IF NOT EXISTS tbl_post_comment_files (
	comment_id INT NOT NULL,
		INDEX index_comment_id (comment_id),
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
		INDEX index_comment_interaction_id (comment_id),
	comment_id INT NOT NULL,
		INDEX index_comment_id (comment_id),
		FOREIGN KEY (comment_id) REFERENCES tbl_post_comments(comment_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	interaction_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	user_id VARCHAR(99) NOT NULL,
		INDEX index_user_id (user_id),
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	interaction_type ENUM('liked', 'commented') NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_post_comment_mentions;
CREATE TABLE IF NOT EXISTS tbl_post_comment_mentions (
	mention_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
		INDEX index_mention_id (mention_id),
	comment_id INT NOT NULL,
		INDEX index_comment_id (comment_id),
		FOREIGN KEY (comment_id) REFERENCES tbl_post_comments(comment_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	user_id VARCHAR(99) NOT NULL,
		INDEX index_user_id (user_id),
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE
) ENGINE = Innodb;

-- POOL
DROP TABLE IF EXISTS tbl_pool;
CREATE TABLE IF NOT EXISTS tbl_pool (
	pool_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
		INDEX index_pool_id (pool_id),
	pool_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	group_id INT NOT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	author_id VARCHAR(99) NOT NULL,
		INDEX index_author_id (author_id),
		FOREIGN KEY (author_id) REFERENCES tbl_users_account(user_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_pool_options;
CREATE TABLE IF NOT EXISTS tbl_pool_options (
	option_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
		INDEX index_option_id (option_id),
	pool_id INT NOT NULL,
		INDEX index_pool_id (pool_id),
		FOREIGN KEY (pool_id) REFERENCES tbl_pool(pool_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	option_text VARCHAR(7999) NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_pool_choice_files;
CREATE TABLE IF NOT EXISTS tbl_pool_choice_files (
	option_id INT NOT NULL,
		INDEX index_option_id (option_id),
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
		INDEX index_option_id (option_id),
		FOREIGN KEY (option_id) REFERENCES tbl_pool_options(option_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	voter_id VARCHAR(99) NOT NULL,
		INDEX index_voter_id (voter_id),
		FOREIGN KEY (voter_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE
) ENGINE = Innodb;

-- CHAT
DROP TABLE IF EXISTS tbl_chat;
CREATE TABLE IF NOT EXISTS tbl_chat (
	chat_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
		INDEX index_chat_id (chat_id),
	chat_type ENUM('pair', 'group') NOT NULL,
	group_id INT NOT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	latest_stamp DATETIME NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_chat_read_states;
CREATE TABLE IF NOT EXISTS tbl_chat_read_states (
	chat_id INT NOT NULL,
		INDEX index_chat_id (chat_id),
		FOREIGN KEY (chat_id) REFERENCES tbl_chat(chat_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	user_id VARCHAR(99) NOT NULL,
		INDEX index_user_id (user_id),
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
		INDEX index_message_id (message_id),
	message_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	chat_id INT NOT NULL,
		INDEX index_chat_id (chat_id),
		FOREIGN KEY (chat_id) REFERENCES tbl_chat(chat_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	sender_id VARCHAR(99) NOT NULL,
		INDEX index_sender_id (sender_id),
		FOREIGN KEY (sender_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	message_text VARCHAR(7999),
	to_message_id INT NULL,
		INDEX index_to_message_id (to_message_id),
		FOREIGN KEY (to_message_id) REFERENCES tbl_chat_messages(message_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_chat_message_files;
CREATE TABLE IF NOT EXISTS tbl_chat_message_files (
	message_id INT NOT NULL,
		INDEX index_message_id (message_id),
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
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	category_name VARCHAR(99) NOT NULL
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_tasks;
CREATE TABLE IF NOT EXISTS tbl_tasks (
	task_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
		INDEX index_task_id (task_id),
	group_id INT NOT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	task_status ENUM('draft', 'scheduled', 'published', 'closed') NOT NULL DEFAULT 'draft',
	period ENUM('prelim', 'mid-term', 'semi-finals', 'finals') NOT NULL,
	category_name VARCHAR(99) NOT NULL,
	created_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	due_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	author_id VARCHAR(99) NOT NULL,
		INDEX index_author_id (author_id),
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
		INDEX index_question_id (question_id),
	task_id INT NOT NULL,
		INDEX index_task_id (task_id),
		FOREIGN KEY (task_id) REFERENCES tbl_tasks(task_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	duration INT NOT NULL DEFAULT 0,
	points INT NOT NULL DEFAULT 0,
	question_type ENUM('true_or_false', 'multiple_choices', 'identification') NOT NULL,
	question_text VARCHAR(7999),
	answer VARCHAR(7999)
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_task_question_file;
CREATE TABLE IF NOT EXISTS tbl_task_question_file (
	question_id INT NOT NULL,
		INDEX index_question_id (question_id),
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
		INDEX index_choice_id (choice_id),
	question_id INT NOT NULL,
		INDEX index_question_id (question_id),
		FOREIGN KEY (question_id) REFERENCES tbl_task_questions(question_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	choice_text VARCHAR(7999)
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_task_question_response;
CREATE TABLE IF NOT EXISTS tbl_task_question_response (
	question_id INT NOT NULL,
		INDEX index_question_id (question_id),
		FOREIGN KEY (question_id) REFERENCES tbl_task_questions(question_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	respondent_id VARCHAR(99) NOT NULL,
		INDEX index_respondent_id (respondent_id),
		FOREIGN KEY (respondent_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	response_text VARCHAR(7999)
) ENGINE = Innodb;

-- GROUP/GRADE
DROP TABLE IF EXISTS tbl_grades;
CREATE TABLE IF NOT EXISTS tbl_grades (
	group_id INT NOT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	period ENUM('prelim', 'mid-term', 'semi-finals', 'finals') NOT NULL,
	completion DECIMAL NOT NULL DEFAULT 0,
	gpa DECIMAL NOT NULL DEFAULT 0
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_grade_component;
CREATE TABLE IF NOT EXISTS tbl_grade_component (
	group_id INT NOT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	period ENUM('prelim', 'mid-term', 'semi-finals', 'finals') NOT NULL,
	component_name VARCHAR(99) NOT NULL,
	weight_percentage INT NOT NULL DEFAULT 0
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_grade_academic_records;
CREATE TABLE IF NOT EXISTS tbl_grade_academic_records (
	assessment_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	group_id INT NOT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	period ENUM('prelim', 'mid-term', 'semi-finals', 'finals') NOT NULL,
	component_name VARCHAR(99) NOT NULL,
	assessment_no VARCHAR(99) NOT NULL,
	max_score INT NOT NULL DEFAULT 0,
	is_synced BOOLEAN DEFAULT FALSE
) ENGINE = Innodb;

DROP TABLE IF EXISTS tbl_grade_student_records;
CREATE TABLE IF NOT EXISTS tbl_grade_student_records (
	score_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
		INDEX index_score_id (score_id),
	assessment_id INT NOT NULL,
		INDEX index_assessment_id (assessment_id),
		FOREIGN KEY (assessment_id) REFERENCES tbl_grade_academic_records(assessment_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	student_id VARCHAR(99) NOT NULL,
		INDEX index_student_id (student_id),
		FOREIGN KEY (student_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	score INT NOT NULL DEFAULT 0
) ENGINE = Innodb;

-- USERS/NOTIFICATION
DROP TABLE IF EXISTS tbl_users_notification;
CREATE TABLE IF NOT EXISTS tbl_users_notification (
	notification_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
		INDEX index_notification_id (notification_id),
	notification_stamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	sender_id VARCHAR(99) NULL DEFAULT NULL,
		INDEX index_sender_id (sender_id),
		FOREIGN KEY (sender_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE, 
	recipient_id VARCHAR(99) NULL DEFAULT NULL,
		INDEX index_recipient_id (recipient_id),
		FOREIGN KEY (recipient_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	notification_text VARCHAR(99) NOT NULL,
	notification_type ENUM(
		'CREATED_GROUP',
		'PENDING_GROUP_INVITATION',
		'ACCEPTED_GROUP_INVITATION',
		'REQUESTING_GROUP_JOIN',
		'ACCEPTED_GROUP_JOIN',
		'KICKED_YOU',
		'COMMENTED_YOUR_POST',
		'REPLIED_POST',
		'LIKED_POST',
		'LIKED_COMMENT', 
		'REPLIED_YOUR_COMMENT'
		'POST_APPROVE',
		'POSTED_TASK', 
		'TURNED_GROUP_MODERATOR',
		'REQUESTED_POST_APPROVAL',
		'REQUESTED_GROUP_POST_APPROVAL',
		'POSTED_A_POST',
		'POSTED_IN_GROUP',
		'TAGGED_YOU_IN_POST',
		'TAGGED_YOU_IN_A_POST_IN_GROUP',
		'MENTIONED_YOU_IN_COMMENT',
		'MENTIONED_YOU_IN_COMMENT_IN_GROUP',
		'COMMENTED_ON_A_POST_THAT_YOU_ARE_TAGGED',
		'YOU_POSTED_A_POST_IN_GROUP',
		'YOU_POSTED_A_POST',
		'REQUESTED_COMMENT_APPROVAL_IN_GROUP',
		'REQUESTED_COMMENT_APPROVAL'
	) NOT NULL,
	target_url VARCHAR(7999) NOT NULL,
	is_viewed BOOLEAN NOT NULL DEFAULT FALSE,
	is_opened BOOLEAN NOT NULL DEFAULT FALSE,
	group_id INT NULL DEFAULT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	membership_id INT NULL DEFAULT NULL,
		INDEX index_membership_id (membership_id),
		FOREIGN KEY (membership_id) REFERENCES tbl_group_membership_requests(membership_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	post_id INT NULL DEFAULT NULL,
		INDEX index_post_id (post_id),
		FOREIGN KEY (post_id) REFERENCES tbl_posts(post_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	comment_id INT NULL DEFAULT NULL,
		INDEX index_comment_id (comment_id),
		FOREIGN KEY (comment_id) REFERENCES tbl_post_comments(comment_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	post_interaction_id INT NULL DEFAULT NULL,
		INDEX index_post_interaction_id (post_interaction_id),
		FOREIGN KEY (post_interaction_id) REFERENCES tbl_post_interactions(post_interaction_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	comment_interaction_id INT NULL DEFAULT NULL,
		INDEX index_comment_interaction_id (comment_interaction_id),
		FOREIGN KEY (comment_interaction_id) REFERENCES tbl_comment_interactions(comment_interaction_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	task_id INT NULL DEFAULT NULL,
		INDEX index_task_id (task_id),
		FOREIGN KEY (task_id) REFERENCES tbl_tasks(task_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
) ENGINE = Innodb;

ALTER TABLE tbl_users_notification MODIFY COLUMN notification_type ENUM(
		'CREATED_GROUP',
		'PENDING_GROUP_INVITATION',
		'ACCEPTED_GROUP_INVITATION',
		'REQUESTING_GROUP_JOIN',
		'ACCEPTED_GROUP_JOIN',
		'KICKED_YOU',
		'COMMENTED_YOUR_POST',
		'REPLIED_POST',
		'LIKED_POST',
		'LIKED_COMMENT', 
		'REPLIED_YOUR_COMMENT',
		'POST_APPROVE',
		'POSTED_TASK', 
		'TURNED_GROUP_MODERATOR',
		'REQUESTED_POST_APPROVAL',
		'REQUESTED_GROUP_POST_APPROVAL',
		'POSTED_A_POST',
		'POSTED_IN_GROUP',
		'TAGGED_YOU_IN_POST',
		'TAGGED_YOU_IN_A_POST_IN_GROUP',
		'MENTIONED_YOU_IN_COMMENT',
		'MENTIONED_YOU_IN_COMMENT_IN_GROUP',
		'COMMENTED_ON_A_POST_THAT_YOU_ARE_TAGGED',
		'YOU_POSTED_A_POST_IN_GROUP',
		'YOU_POSTED_A_POST',
		'REQUESTED_COMMENT_APPROVAL_IN_GROUP',
		'REQUESTED_COMMENT_APPROVAL'
) NOT NULL;

DROP TABLE IF EXISTS tbl_users_notification_mutes;
CREATE TABLE IF NOT EXISTS tbl_users_notification_mutes (
	user_id VARCHAR(99) NOT NULL,
		INDEX index_user_id (user_id),
		FOREIGN KEY (user_id) REFERENCES tbl_users_account(user_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	group_id INT NULL DEFAULT NULL,
		INDEX index_group_id (group_id),
		FOREIGN KEY (group_id) REFERENCES tbl_groups(group_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	post_id INT NULL DEFAULT NULL,
		INDEX index_post_id (post_id),
		FOREIGN KEY (post_id) REFERENCES tbl_posts(post_id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
	comment_id INT NULL DEFAULT NULL,
		INDEX index_comment_id (comment_id),
		FOREIGN KEY (comment_id) REFERENCES tbl_post_comments(comment_id) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE
) ENGINE = Innodb;

-- INITIAL
DESCRIBE tbl_users_account;
DESCRIBE tbl_users_profile;

SELECT * FROM tbl_users_account;
SELECT * FROM tbl_users_profile;

DELETE FROM tbl_users_account;
DELETE FROM tbl_users_profile;

SET @username = 'student';
SET @password = '$2a$11$eyXlppBlvJwv2fYtWRGa5eV3eCgjVTTZBmKyNs3joGX/b8uV13vPq';
SET @role = 'student';
SET @gmail = 'student';

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
	CONCAT(@gmail, n, '@gmail.com') gmail
FROM recursion;

SET @username = 'admin';
SET @password = '$2a$11$eyXlppBlvJwv2fYtWRGa5eV3eCgjVTTZBmKyNs3joGX/b8uV13vPq';
SET @role = 'admin';
SET @gmail = 'admin';

INSERT INTO tbl_users_account(username, password, role, gmail)
SELECT
	@username username,
	@password password,
	@role role,
	CONCAT(@gmail, '@gmail.com') gmail;

INSERT INTO tbl_users_profile(user_id, full_name, course)
SELECT 
user_id, 
gmail, 
CASE
	WHEN role = 'admin' THEN ''
	ELSE (
		SELECT ELT(FLOOR(RAND() * 6) + 1, 'BSCRIM', 'BSED', 'BSDC', 'BSHM', 'BSIT', 'BSTM')
	)
END course
FROM tbl_users_account;

UPDATE tbl_users_account SET is_moderator = TRUE WHERE username IN ('student6', 'student7');

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