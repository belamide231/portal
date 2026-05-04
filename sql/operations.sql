-- CONNECTION: jdbc:mysql://127.0.0.1:3306/cec_portal?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=Asia/Manila

USE cec_portal;

DELETE FROM tbl_groups;
DELETE FROM tbl_group_members;
DELETE FROM tbl_users_notification;
DELETE FROM tbl_group_membership_requests;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [1]
 * GROUP/CREATING_GROUP
 * When an admin/instructor creates a group. 
 * group's author's perspective. *clicks notification* navigates: 'group/:groupId'
 * */
DESCRIBE tbl_groups;
DESCRIBE tbl_group_members;
DESCRIBE tbl_users_notification;
DESCRIBE tbl_group_membership_requests;

DESCRIBE tbl_tasks;
DESCRIBE tbl_task_questions;
DESCRIBE tbl_task_question_choices;

SELECT * FROM tbl_groups;
SELECT * FROM tbl_group_members;
SELECT * FROM tbl_users_notification;
SELECT * FROM tbl_group_membership_requests;
SELECT * FROM tbl_users_connection;

ROLLBACK;
COMMIT;
START TRANSACTION;

-- PARAMETERS [1]
SET @user_id = (SELECT user_id FROM tbl_users_account WHERE username = 'admin' LIMIT 1);
SET @group_type = 'class';
SET @group_name = 'FREE ELEC 3';

-- SQL [1]
INSERT INTO tbl_groups(group_type, author_id, group_name) 
SELECT 
	@group_type group_type, 
	@user_id author_id, 
	@group_name group_name;

SET @group_id = LAST_INSERT_ID();

INSERT INTO tbl_group_members(group_id, member_id, group_role, is_group_moderator)
SELECT 
	@group_id group_id,
	@user_id member_id, 
	'group_author' group_role,
    TRUE is_group_moderator
WHERE NOT EXISTS (
	SELECT TRUE FROM tbl_group_members WHERE group_id = @group_id AND member_id = @user_id
);

INSERT INTO tbl_users_notification(notification_text, notification_type, target_url, group_id)
SELECT 
	CONCAT(group_type, ' ', group_name, ' successfully created') notification_text,
	'CREATED_GROUP' notification_type,
	CONCAT('group', '/', @group_id) target_url,
	@group_id group_id
FROM tbl_groups
WHERE group_id = @group_id;

SELECT 
	LAST_INSERT_ID() notification_id, 
	connection_id 
FROM tbl_users_connection 
WHERE user_id = @user_id;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [2] 
 * GROUP/INVITING_USERS_IN_GROUP
 * When an admin/instructor invites users to join the group.
 * invited user's perspective. *clicks notification* navigates: 'group/:groupId'
 * */
DESCRIBE tbl_group_membership_requests;
DESCRIBE tbl_users_notification;

SELECT * FROM tbl_group_membership_requests;
SELECT * FROM tbl_users_notification;
SELECT * FROM tbl_users_connection;

ROLLBACK;
COMMIT;
START TRANSACTION;

-- PARAMETERS [2]
SET @candidates_id = CONCAT(
	(SELECT user_id FROM tbl_users_account WHERE username = 'student3' LIMIT 1), 
	' * , \n ', 
	(SELECT user_id FROM tbl_users_account WHERE username = 'student2' LIMIT 1),
	'              ', 
	(SELECT user_id FROM tbl_users_account WHERE username = 'student1' LIMIT 1)
);
SET @group_id = (SELECT group_id FROM tbl_groups WHERE group_name = 'FREE ELEC 3' LIMIT 1);
SET @user_id = (SELECT user_id FROM tbl_users_account WHERE username = 'admin' LIMIT 1);

-- SQL [2]
INSERT INTO tbl_group_membership_requests(group_id, candidate_id, referrer_id, origin)
SELECT
	group_id 									group_id, 
	candidate_id							candidate_id, 
	@user_id 									referrer_id, 
	origin										origin
FROM (
	WITH RECURSIVE recursion AS (
	    SELECT 
	        TRIM(REGEXP_REPLACE(CONVERT(@candidates_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')) AS remaining, 
	        SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(CONVERT(@candidates_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')), ' ', 1) AS element
	    UNION ALL
	    SELECT 
	        TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), 
	        SUBSTRING_INDEX(TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), ' ', 1)
	    FROM recursion
	    WHERE remaining != element AND remaining != ''
	)
	SELECT @group_id group_id, element candidate_id, 'invited' origin FROM recursion
) ft
WHERE ft.candidate_id NOT IN (
	SELECT 
		candidate_id
	FROM tbl_group_membership_requests
	WHERE group_id = @group_id
);

SET @starting_membership_id = LAST_INSERT_ID() - ROW_COUNT();

INSERT INTO tbl_users_notification(sender_id, recipient_id, notification_text, notification_type, target_url, membership_id, group_id)
SELECT 
    @user_id 																					sender_id,
	t1.candidate_id 																			recipient,
	CONCAT(t3.full_name, ' invited you to join ', t2.group_type, ' ', t2.group_name) 		    notification_text,
	'PENDING_GROUP_INVITATION' 																	notification_type,
	CONCAT('group', '/', @group_id) 															target_url,
	t1.membership_id 																			membership_id,
	@group_id 																					group_id
FROM tbl_group_membership_requests t1
JOIN tbl_groups t2
	ON t1.group_id = t2.group_id
JOIN tbl_users_profile t3
	ON t3.user_id = @user_id
WHERE t1.membership_id > @starting_membership_id
AND t1.referrer_id = @user_id
AND t1.group_id = @group_id;

SET @starting_notification_id = (LAST_INSERT_ID() - ROW_COUNT());

SELECT 
	t1.notification_id,
	t2.connection_id
-- 	,(SELECT full_name FROM tbl_users_profile WHERE t1.recipient_id = user_id) full_name
FROM tbl_users_notification t1
JOIN tbl_users_connection t2
	ON t1.recipient_id = t2.user_id
WHERE t1.notification_id > @starting_notification_id;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [3]
 * GROUP/REQUESTING_JOIN_GROUP 
 * When a user sends a request join to the group.
 * group's author's/moderator's perspective. *clicks notification* navigates: 'group/:groupId/pending-members/search?membershipId=5'
 * */
DESCRIBE tbl_group_membership_requests;
DESCRIBE tbl_users_notification;
DESCRIBE tbl_group_members;
DESCRIBE tbl_groups;

SELECT * FROM tbl_group_membership_requests ORDER BY origin_stamp DESC;
SELECT * FROM tbl_users_notification ORDER BY notification_stamp DESC;
SELECT * FROM tbl_group_members ORDER BY join_stamp DESC;
SELECT * FROM tbl_groups ORDER BY group_created_stamp DESC;

INSERT INTO tbl_group_members (group_id, member_id, group_role, is_group_moderator)
SELECT 
	t2.group_id group_id, 
	t1.user_id member_id,
	'group_member' group_role,
    TRUE is_group_moderator
FROM tbl_users_account t1
JOIN tbl_groups t2
	ON t1.username = 'student10' 
	AND t2.group_name = 'FREE ELEC 3';

UPDATE tbl_groups 
SET join_policy = 'request_join' 
WHERE group_name = 'FREE ELEC 3';

ROLLBACK;
COMMIT;
START TRANSACTION;

-- PARAMETERS [3]
SET @group_id = (SELECT group_id FROM tbl_groups WHERE group_name = 'FREE ELEC 3' LIMIT 1);
SET @user_id = (SELECT user_id FROM tbl_users_account WHERE username = 'student6' LIMIT 1);

-- SQL [3]
INSERT INTO tbl_group_membership_requests(group_id, candidate_id, origin)
SELECT
	@group_id 				group_id, 
	@user_id 					candidate_id,
	'request_join' 		origin
WHERE NOT EXISTS(
	SELECT 1 FROM tbl_group_membership_requests WHERE group_id = @group_id AND candidate_id = @user_id	
) AND EXISTS (
	SELECT TRUE FROM tbl_groups WHERE group_id = @group_id AND join_policy = 'request_join'
);

SET @membership_id = LAST_INSERT_ID();

INSERT INTO tbl_group_members (group_id, member_id)
SELECT 
	@group_id 	group_id,
	@user_id 		member_id
WHERE NOT EXISTS (
	SELECT TRUE FROM tbl_group_members WHERE group_id = @group_id AND member_id = @user_id
) AND EXISTS (
	SELECT TRUE FROM tbl_groups WHERE group_id = @group_id AND join_policy = 'open'
);

INSERT INTO tbl_users_notification(sender_id, recipient_id, notification_text, notification_type, target_url, membership_id, group_id)
SELECT 
	@user_id 																																															user_id,
	t1.member_id 																																													recipient_id,
	CONCAT(t2.full_name, ' requested to join ', t3.group_type, ' ', t3.group_name) 												notification_text,
	'REQUESTING_GROUP_JOIN' 																																							notification_type,
	CONCAT('group', '/', @group_id, '/', 'pending-members', '/search?', 'full_name', '=', t2.full_name) 	target_url,
	@membership_id 																																												membership_id,
	@group_id 																																														group_id
FROM tbl_group_members t1
JOIN tbl_users_profile t2
	ON t2.user_id = @user_id
JOIN tbl_groups t3
	ON t3.group_id = @group_id
WHERE t1.group_id = @group_id
AND t1.is_group_moderator IS TRUE
AND EXISTS (
	SELECT TRUE FROM tbl_groups WHERE group_id = @group_id AND join_policy = 'request_join'
);

SET @starting_notification_id = (LAST_INSERT_ID() - ROW_COUNT());

SELECT 
	t1.notification_id,
	t2.connection_id
-- 	,(SELECT full_name FROM tbl_users_profile WHERE t1.recipient_id = user_id) full_name
FROM tbl_users_notification t1
JOIN tbl_users_connection t2
	ON t1.recipient_id = t2.user_id
WHERE EXISTS (
	SELECT TRUE FROM tbl_groups WHERE group_id = @group_id AND join_policy = 'request_join'
)
AND t1.notification_id > @starting_notification_id;
	

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [4]
 * GROUP/ACCEPTING_GROUP_REQUEST_JOIN 
 * When an admin/instructor accepts user's request on joining group.
 * user's perspective. *clicks notification* navigates: 'group/:groupId'
 * */
DESCRIBE tbl_group_membership_requests;
DESCRIBE tbl_users_notification;
DESCRIBE tbl_groups;

SELECT * FROM tbl_group_membership_requests ORDER BY origin_stamp DESC;
SELECT * FROM tbl_users_notification ORDER BY notification_stamp DESC;
SELECT * FROM tbl_group_members ORDER BY join_stamp DESC;

ROLLBACK;
COMMIT;
START TRANSACTION;

-- PARAMETERS
SET @user_id = (SELECT user_id FROM tbl_users_account WHERE ROLE = 'admin');
SET @membership_id = (
	SELECT 
		membership_id
	FROM tbl_group_membership_requests t1 
	JOIN tbl_users_account t2
		ON t1.candidate_id = t2.user_id
	WHERE t2.username = 'student6'
	AND t1.origin = 'request_join'
);

-- SQL
INSERT INTO tbl_group_members(group_id, member_id, referrer_id)
SELECT
	group_id,
	candidate_id member_id,
	@user_id referrer_id
FROM tbl_group_membership_requests
WHERE membership_id = @membership_id
AND NOT EXISTS (
	SELECT 
		TRUE
	FROM tbl_group_membership_requests t1
	JOIN tbl_group_members t2
		ON t1.candidate_id = t2.member_id 
		AND t1.group_id = t2.group_id
	WHERE t1.membership_id = @membership_id
);

INSERT INTO tbl_users_notification(sender_id, recipient_id, notification_text, notification_type, target_url, group_id)
SELECT 
	@user_id sender_id,
	t1.candidate_id recipient_id,
	CONCAT(t2.full_name, ' accepted your request to join ', t3.group_type, ' ', t3.group_name) notification_text,
	'ACCEPTED_GROUP_JOIN' notification_type,
	CONCAT('group', '/', t1.group_id) target_url,
	t1.group_id group_id
FROM tbl_group_membership_requests t1
JOIN tbl_users_profile t2
	ON t2.user_id = @user_id
JOIN tbl_groups t3 
	ON t1.group_id = t3.group_id
WHERE t1.membership_id = @membership_id;

DELETE FROM tbl_group_membership_requests WHERE membership_id = @membership_id;

SELECT 
	t1.notification_id, 
	t2.connection_id
FROM tbl_users_notification t1
JOIN tbl_users_connection t2
	ON t1.recipient_id = t2.user_id
WHERE t1.notification_id = LAST_INSERT_ID();

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [5]
 * GROUP/ACCEPTING_GROUP_INVITATION
 * When a user accepts author's/moderator's group invitation.
 * author's perspective. *clicks notification* navigates: 'group/:groupId/members/search?full_name=student3'
 * */
DESCRIBE tbl_users_notification;
DESCRIBE tbl_groups;
DESCRIBE tbl_group_members;
DESCRIBE tbl_group_membership_requests;

SELECT * FROM tbl_users_notification ORDER BY notification_stamp DESC;
SELECT * FROM tbl_groups ORDER BY group_created_stamp DESC;
SELECT * FROM tbl_group_members ORDER BY join_stamp DESC;
SELECT * FROM tbl_group_membership_requests ORDER BY origin_stamp DESC;

ROLLBACK;
COMMIT;
START TRANSACTION;

-- PARAMETERS [5]
SET @membership_id = (
	SELECT 
		membership_id
	FROM tbl_group_membership_requests t1
	JOIN tbl_users_account t2
		ON t1.candidate_id = t2.user_id
	WHERE t2.username = 'student2'
	AND t1.origin = 'invited'
	LIMIT 1
);

-- SQL [5]
INSERT INTO tbl_group_members(group_id, member_id, referrer_id)
SELECT
	group_id,
	candidate_id member_id,
	@user_id referrer_id
FROM tbl_group_membership_requests
WHERE membership_id = @membership_id
AND NOT EXISTS (
	SELECT TRUE FROM tbl_group_members WHERE group_id = @group_id AND member_id = @candidate_id
) AND NOT EXISTS (
	SELECT 
		TRUE
	FROM tbl_group_membership_requests t1
	JOIN tbl_group_members t2
		ON t1.candidate_id = t2.member_id 
		AND t1.group_id = t2.group_id
	WHERE t1.membership_id = @membership_id
);

SELECT 
	candidate_id, referrer_id, group_id
INTO 
	@candidate_id, @referrer_id, @group_id
FROM tbl_group_membership_requests
WHERE membership_id = @membership_id;

DELETE FROM tbl_group_membership_requests WHERE membership_id = @membership_id;

INSERT INTO tbl_users_notification(sender_id, recipient_id, notification_text, notification_type, target_url, group_id)
SELECT
	@candidate_id sender_id,
	@referrer_id recipient_id,
	CONCAT(full_name, ' accepted your group invitation') notification_text,
	'ACCEPTED_GROUP_INVITATION' notification_type,
	CONCAT('group', '/', @group_id, '/', 'members', '/search?', 'full_name', '=', full_name) target_url,
	@group_id group_id
FROM tbl_users_profile
WHERE @candidate_id = user_id;

SELECT 
	LAST_INSERT_ID() notification_id, 
	connection_id connection_id
-- 	, (SELECT full_name FROM tbl_users_profile WHERE user_id = @referrer_id) full_name
FROM tbl_users_connection
WHERE user_id = @referrer_id;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [6]
 * GROUP/DECLINING_GROUP_INVITATION
 * When a user decline's author's/moderator's group invitation.
 * */
DESCRIBE tbl_group_membership_requests;

SELECT * FROM tbl_group_membership_requests ORDER BY origin_stamp DESC;
SELECT * FROM tbl_users_notification ORDER BY notification_stamp DESC;

START TRANSACTION;
ROLLBACK;

-- PARAMETERS [6]
SET @membership_id = 12;

-- SQL [6]
DELETE FROM tbl_group_membership_requests WHERE membership_id = @membership_id;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [7]
 * GROUP/DECLINING_JOIN_GROUP_REQUEST
 * When an author/moderator declines user's invitation.
 * */
DESCRIBE tbl_users_notification;
DESCRIBE tbl_group_membership_requests;

SELECT * FROM tbl_users_notification ORDER BY notification_stamp DESC;
SELECT * FROM tbl_group_membership_requests ORDER BY origin_stamp DESC;
SELECT * FROM tbl_group_members ORDER BY join_stamp DESC;

START TRANSACTION;
ROLLBACK;

-- PARAMETERS [7]
SET @membership_id = 12;

-- SQL [7]
DELETE FROM tbl_group_membership_requests WHERE membership_id = @membership_id;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [8]
 * GROUP/CANCELLING_JOIN_GROUP_REQUEST
 * When a user cancels request join group.
 * */
DESCRIBE tbl_users_notification;
DESCRIBE tbl_group_membership_requests;

SELECT * FROM tbl_users_notification ORDER BY notification_stamp DESC;
SELECT * FROM tbl_group_membership_requests ORDER BY origin_stamp DESC;
SELECT * FROM tbl_group_members ORDER BY join_stamp DESC;

START TRANSACTION;
ROLLBACK;

-- PARAMETERS [8]
SET @user_id = (SELECT user_id FROM tbl_users_account WHERE username = 'student6' LIMIT 1);
SET @group_id = 2;

-- SQL [8]
DELETE FROM tbl_group_membership_requests WHERE group_id = @group_id AND candidate_id = @user_id AND origin = 'request_join';

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [9]
 * GROUP/CANCELLING_GROUP_INVITATION_REQUEST
 * When an author/moderator cancels an invitation group request.
 * */
DESCRIBE tbl_users_notification;
DESCRIBE tbl_group_membership_requests;

SELECT * FROM tbl_users_notification ORDER BY notification_stamp DESC;
SELECT * FROM tbl_group_membership_requests ORDER BY origin_stamp DESC;
SELECT * FROM tbl_group_members ORDER BY join_stamp DESC;

START TRANSACTION;
ROLLBACK;

-- PARAMETERS [9]
SET @membership_id = 4;
-- SQL [9]
DELETE FROM tbl_group_membership_requests WHERE membership_id = @membership_id;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [10]
 * GROUP/LEAVING_GROUP
 * When an author/moderator/member leaves group.
 * */
DESCRIBE tbl_groups;
DESCRIBE tbl_group_members;

SELECT * FROM tbl_groups ORDER BY group_created_stamp DESC;
SELECT * FROM tbl_group_members ORDER BY join_stamp DESC;

ROLLBACK;
COMMIT;
START TRANSACTION;

-- PARAMETERS [10]
SET @group_id = 3;
SET @user_id = (SELECT user_id FROM tbl_users_account WHERE username = 'student10');

-- SQL [10]
DELETE FROM tbl_users_notification WHERE recipient_id = @user_id AND group_id = @group_id;
DELETE FROM tbl_group_members WHERE group_id = @group_id AND member_id = @user_id;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [11]
 * GROUP/KICKING_MEMBERS
 * When an author/moderator kicks a member in the group.
 * user's perspective. *clicks notification* navigates: 'group/:groupId'
 * */
DESCRIBE tbl_groups;
DESCRIBE tbl_group_members;

SELECT * FROM tbl_users_account;
SELECT * FROM tbl_groups ORDER BY group_created_stamp DESC;
SELECT * FROM tbl_group_members ORDER BY join_stamp DESC;
SELECT * FROM tbl_users_notification ORDER BY notification_id DESC;

ROLLBACK;
COMMIT;
START TRANSACTION;

DESCRIBE tbl_group_members;

-- PARAMETERS [11]
SET @group_id = (SELECT group_id FROM tbl_groups WHERE group_name = 'FREE ELEC 3' LIMIT 1);
SET @user_id = (SELECT user_id FROM tbl_users_account WHERE username = 'admin');
SET @members_id = 'bfeeb8db-4527-11f1-a263-e4b97aea4dc2 bfeec03d-4527-11f1-a263-e4b97aea4dc2';

-- SQL [11]
DELETE FROM tbl_users_notification WHERE recipient_id IN (
	WITH RECURSIVE recursion AS (
	    SELECT 
	        TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')) AS remaining, 
	        SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')), ' ', 1) AS element
	    UNION ALL
	    SELECT 
	        TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), 
	        SUBSTRING_INDEX(TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), ' ', 1)
	    FROM recursion
	    WHERE remaining != element AND remaining != ''
	)
	SELECT ELEMENT 
	FROM recursion
	WHERE ELEMENT != @user_id
	AND ELEMENT IN (
		SELECT 
			member_id
		FROM tbl_group_members
		WHERE group_id = @group_id
	)
) AND group_id = @group_id;

INSERT INTO tbl_users_notification(sender_id, recipient_id, notification_text, notification_type, target_url, group_id)
WITH RECURSIVE recursion AS (
    SELECT 
        TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')) AS remaining, 
        SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')), ' ', 1) AS element
    UNION ALL
    SELECT 
        TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), 
        SUBSTRING_INDEX(TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), ' ', 1)
    FROM recursion
    WHERE remaining != element AND remaining != ''
)
SELECT 
	@user_id sender_id,
	ELEMENT recipient_id,
	CONCAT(t2.full_name, ' kicked you out from ', t3.group_type, ' ', t3.group_name) notification_text,
	'KICKED_YOU' notification_type,
	CONCAT('group', '/', @group_id) target_url,
	@group_id group_id
FROM recursion t1
JOIN tbl_users_profile t2
	ON t2.user_id = @user_id
JOIN tbl_groups t3
	ON t3.group_id = @group_id
WHERE (SELECT join_policy FROM tbl_groups WHERE group_id = @group_id) != 'open'
AND ELEMENT != @user_id
AND ELEMENT IN (
	SELECT 
		member_id
	FROM tbl_group_members
	WHERE group_id = @group_id
);

DELETE FROM tbl_group_members 
WHERE group_id = @group_id 
AND member_id != @user_id
AND member_id IN (
	WITH RECURSIVE recursion AS (
	    SELECT 
	        TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')) AS remaining, 
	        SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')), ' ', 1) AS element
	    UNION ALL
	    SELECT 
	        TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), 
	        SUBSTRING_INDEX(TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), ' ', 1)
	    FROM recursion
	    WHERE remaining != element AND remaining != ''
	)
	SELECT element FROM recursion
);

SET @starting_notification_id = LAST_INSERT_ID() - ROW_COUNT();

SELECT 
	t1.notification_id notification_id,
	t2.connection_id recipient_id
-- 	, (SELECT username FROM tbl_users_account WHERE user_id = t1.recipient_id) username
FROM tbl_users_notification t1
JOIN tbl_users_connection t2
	ON t1.recipient_id = t2.user_id
WHERE t1.notification_id > @starting_notification_id;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [12]
 * GROUP/EDITING_GROUP
 * When an author edits group.
 * member's perspective. *clicks notification* navigates: 'group/:groupId'
 * */

DESCRIBE tbl_groups;
DESCRIBE tbl_users_notification;

SELECT * FROM tbl_users_notification ORDER BY notification_stamp DESC;
SELECT * FROM tbl_groups ORDER BY group_created_stamp DESC;

START TRANSACTION;
ROLLBACK;

-- PARAMETERS [12]
SET @user_id = '3849a541-4194-11f1-a263-e4b97aea4dc2';
SET @group_id = 3;
SET @join_policy = 'request_join';
SET @post_policy = 'everyone';
SET @group_name = 'FREE ELEC 3';
SET @group_description = '';

-- SQL [12]
DELETE t1
FROM tbl_users_notification t1
JOIN tbl_groups t2
	ON t1.group_id = t2.group_id
WHERE t1.group_id = @group_id 
AND t1.notification_type = 'UPDATED_GROUP'
AND (t2.group_name != @group_name OR t2.group_description != @group_desciption);

INSERT INTO tbl_users_notification(sender_id, recipient_id, notification_text, notification_type, target_url, group_id)
SELECT 
	@user_id sender_id,
	t1.member_id recipient_id,
	CASE 
		WHEN t1.member_id = t2.author_id THEN CONCAT('you just updated the ', t2.group_type, ' ', t2.group_name)
		ELSE CONCAT(t3.full_name, ' updated the ', t2.group_type, ' ', t2.group_name)
	END notification_text,
	'UPDATED_GROUP' notification_type,
	CONCAT('group', '/', @group_id) target_url,
	@group_id group_id
FROM tbl_group_members t1
JOIN tbl_groups t2
	ON t1.group_id = t2.group_id
JOIN tbl_users_profile t3
	ON t2.author_id = t3.user_id
WHERE (t2.group_name != @group_name OR t2.group_description != @group_desciption)
AND t1.group_id = @group_id;

UPDATE tbl_groups 
SET join_policy = @join_policy, post_policy = @post_policy, group_name = @group_name, group_description = @group_description
WHERE group_id = @group_id;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [13]
 * GROUP/CHANGING_MEMBER_ROLE
 * When an author updates a member's role.
 * member's perspective. *clicks notification* navigates: 'group/:groupId'
 * */
DESCRIBE tbl_group_members;
DESCRIBE tbl_users_notification;

SELECT * FROM tbl_users_notification ORDER BY notification_stamp DESC;
SELECT * FROM tbl_group_members ORDER BY join_stamp DESC;

ROLLBACK;
COMMIT;
START TRANSACTION;

-- PARAMETERS [13]
SET @group_id = (SELECT group_id FROM tbl_groups WHERE group_name = 'FREE ELEC 3' LIMIT 1);
SET @user_id = 'bff029ff-4527-11f1-a263-e4b97aea4dc2';
SET @members_id = 'bfeeb8db-4527-11f1-a263-e4b97aea4dc2 bfeec03d-4527-11f1-a263-e4b97aea4dc2';
SET @is_group_moderator = TRUE;

-- SQL [13]
DELETE t1
FROM tbl_users_notification t1
JOIN (
	WITH RECURSIVE recursion AS (
	    SELECT 
	        TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')) AS remaining, 
	        SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')), ' ', 1) AS element
	    UNION ALL
	    SELECT 
	        TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), 
	        SUBSTRING_INDEX(TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), ' ', 1)
	    FROM recursion
	    WHERE remaining != element AND remaining != ''
	)
	SELECT 
		ELEMENT
	FROM recursion
	WHERE ELEMENT != @user_id
) t2
	ON t1.recipient_id = t2.ELEMENT
JOIN tbl_group_members t3
	ON t2.ELEMENT = t3.member_id
WHERE t3.group_id = @group_id
AND t3.is_group_moderator != @is_group_moderator;

INSERT INTO tbl_users_notification(sender_id, recipient_id, notification_text, notification_type, target_url, group_id)
WITH RECURSIVE recursion AS (
    SELECT 
        TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')) AS remaining, 
        SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')), ' ', 1) AS element
    UNION ALL
    SELECT 
        TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), 
        SUBSTRING_INDEX(TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), ' ', 1)
    FROM recursion
    WHERE remaining != element AND remaining != ''
)
SELECT 
	@user_id sender_id,
	t1.ELEMENT recipient_id,
	CONCAT(t2.full_name, ' made you a group moderator in ', t5.group_type, ' ', t5.group_name) notification_text,
	'TURNED_GROUP_MODERATOR' notification_type,
	CONCAT('group', '/', @group_id, '/', 'members', '/search?', 'full_name', '=', t3.full_name) target_url,
	@group_id group_id
FROM recursion t1
JOIN tbl_users_profile t2
	ON t2.user_id = @user_id
JOIN tbl_users_profile t3
	ON t1.ELEMENT = t3.user_id
JOIN tbl_group_members t4
	ON t1.ELEMENT = t4.member_id
JOIN tbl_groups t5
	ON t5.group_id = @group_id
WHERE t1.ELEMENT != @user_id
AND t4.is_group_moderator != @is_group_moderator;

SET @starting_notification_id = LAST_INSERT_ID() - ROW_COUNT();

UPDATE tbl_group_members t1
JOIN (
	WITH RECURSIVE recursion AS (
	    SELECT 
	        TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')) AS remaining, 
	        SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(CONVERT(@members_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')), ' ', 1) AS element
	    UNION ALL
	    SELECT 
	        TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), 
	        SUBSTRING_INDEX(TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), ' ', 1)
	    FROM recursion
	    WHERE remaining != element AND remaining != ''
	)
	SELECT 
		ELEMENT
	FROM recursion
	WHERE ELEMENT != @user_id
) t2
	ON t1.member_id = t2.ELEMENT
SET t1.is_group_moderator = @is_group_moderator
WHERE t1.group_id = @group_id
AND t1.is_group_moderator != @is_group_moderator;

SELECT 
	t1.notification_id notification_id,
	t2.connection_id recipient_id
-- 	, (SELECT username FROM tbl_users_account WHERE user_id = t1.recipient_id) username
FROM tbl_users_notification t1
JOIN tbl_users_connection t2
	ON t1.recipient_id = t2.user_id
WHERE t1.notification_id > @starting_notification_id;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [14]
 * CREATING_POST
 * When an admin/instructor/author/student/member creates a post.
 * moderator/author/admin's perspective. *clicks notification* navigates: 'group/:groupId'
 * */

DESCRIBE tbl_posts;
DESCRIBE tbl_users_notification;

SELECT * FROM tbl_posts;
SELECT * FROM tbl_users_notification t1 JOIN tbl_users_account t2 ON t1.recipient_id = t2.user_id;
SELECT * FROM tbl_users_account;
SELECT * FROM tbl_portal_policy;
SELECT * FROM tbl_groups;
SELECT t2.username, t1.is_group_moderator FROM tbl_group_members t1 JOIN tbl_users_account t2 ON t1.member_id = t2.user_id;

DELETE FROM tbl_users_notification;
DELETE FROM tbl_posts;

ROLLBACK;
COMMIT;
START TRANSACTION;

-- PARAMETERS [14]
SET @group_id = NULL;
SET @user_id = (SELECT user_id FROM tbl_users_account WHERE username = 'student6');
SET @post_text = 'More practice problems for the midterm exam, please!';
SET @is_important = TRUE;

-- SQL [14]
INSERT INTO tbl_posts(group_id, author_id, post_text, is_important, post_status)
SELECT
	@group_id group_id,
	@user_id author_id,
	@post_text post_text,
	@is_important is_important,
	CASE
		WHEN @group_id IS NULL AND t1.post_policy = 'public' THEN 'posted'
		WHEN @group_id IS NULL AND t1.post_policy = 'moderated' AND t2.ROLE = 'student' AND t2.is_moderator = FALSE THEN 'pending'
		WHEN @group_id IS NULL AND t1.post_policy = 'moderated' AND (t2.ROLE IN ('instructor', 'admin') OR t2.is_moderator = TRUE) THEN 'posted'
        WHEN @group_id IS NULL AND t1.post_policy = 'restricted' AND t2.ROLE = 'admin' THEN 'posted'
        WHEN @group_id IS NOT NULL AND t3.post_policy = 'public' THEN 'posted'
        WHEN @group_id IS NOT NULL AND t3.post_policy = 'moderated' AND (t4.group_role != 'group_author' AND t4.is_group_moderator = FALSE) THEN 'pending'
        WHEN @group_id IS NOT NULL AND t3.post_policy = 'moderated' AND (t4.group_role = 'group_author' OR t4.is_group_moderator = TRUE) THEN 'posted'
        WHEN @group_id IS NOT NULL AND t3.post_policy = 'restricted' AND t4.group_role = 'group_author' THEN 'posted'
        ELSE 'pending'
	END post_status
FROM tbl_portal_policy t1
JOIN tbl_users_account t2
	ON t2.user_id = @user_id
LEFT JOIN tbl_groups t3
    ON @group_id IS NOT NULL 
    AND t3.group_id = @group_id
LEFT JOIN tbl_group_members t4
    ON @group_id IS NOT NULL
    AND t4.group_id = @group_id
    AND t4.member_id = @user_id
WHERE t1.policy_id = 1;

SET @post_id = LAST_INSERT_ID();

INSERT INTO tbl_users_notification(sender_id, recipient_id, notification_text, notification_type, target_url, group_id, post_id)
SELECT 
    @user_id sender_id,
    mt.user_id recipient_id,
    CASE 
        WHEN @group_id IS NOT NULL AND t3.post_status = 'pending' THEN CONCAT(t1.full_name, ' requested a post approval in ', t2.group_type, ' ', t2.group_name)
        WHEN @group_id IS NOT NULL AND t3.post_status = 'posted' THEN CONCAT(t1.full_name, ' posted a post in ', t2.group_type, ' ', t2.group_name)
        WHEN @group_id IS NULL AND t3.post_status = 'pending' THEN CONCAT(t1.full_name, ' requested a post approval')
        WHEN @group_id IS NULL AND t3.post_status = 'posted' THEN CONCAT(t1.full_name, ' posted a post')
    END notification_text,
    CASE 
        WHEN @group_id IS NOT NULL AND t3.post_status = 'pending' THEN 'REQUESTED_GROUP_POST_APPROVAL'
        WHEN @group_id IS NOT NULL AND t3.post_status = 'posted' THEN 'POSTED_A_POST'
        WHEN @group_id IS NULL AND t3.post_status = 'pending' THEN 'REQUESTED_POST_APPROVAL'
        WHEN @group_id IS NULL AND t3.post_status = 'posted' THEN 'POSTED_A_POST'
    END notification_type,
    CASE 
        WHEN @group_id IS NOT NULL THEN CONCAT('group/', @group_id , '/post/', @post_id)
        ELSE CONCAT('post/', @post_id)
    END target_url,
    @group_id group_id,
    @post_id post_id
FROM (
    SELECT
        t1.member_id user_id
    FROM tbl_group_members t1
    JOIN tbl_posts t2
        ON t2.post_id = @post_id
    WHERE (@group_id IS NOT NULL AND t1.group_id = @group_id)
    AND t1.member_id != @user_id
    AND (
        (t1.is_group_moderator = TRUE AND t2.post_status = 'pending') 
        OR
        (t2.is_important = TRUE AND t2.post_status = 'posted')
    )
    UNION ALL
    SELECT
        t1.user_id
    FROM tbl_users_account t1
    JOIN tbl_posts t2
        ON t2.post_id = @post_id
    WHERE @group_id IS NULL
    AND t1.user_id != @user_id
    AND (
        (t1.is_moderator = TRUE AND t2.post_status = 'pending')
        OR
        (t2.is_important = TRUE AND t2.post_status = 'posted')
    )
) mt
LEFT JOIN tbl_users_profile t1
    ON t1.user_id = @user_id
LEFT JOIN tbl_groups t2
    ON t2.group_id = @group_id
JOIN tbl_posts t3
    ON t3.post_id = @post_id;

SET @starting_notification_id = (LAST_INSERT_ID() - ROW_COUNT());

SELECT 
    t1.notification_id, 
    t2.connection_id
FROM tbl_users_notification t1
JOIN tbl_users_connection t2
    ON t1.recipient_id = t2.user_id
WHERE t1.notification_id > @starting_notification_id;

/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/* NO: [15]
 * CREATING_POST
 * When an admin/instructor/author/student/member comments a post/replies a comment.
 * moderator/author/admin's perspective. *clicks notification* navigates: 'group/:groupId'
 * */

DESCRIBE tbl_posts;
DESCRIBE tbl_users_account;
DESCRIBE tbl_users_notification;
DESCRIBE tbl_groups;
DESCRIBE tbl_users_connection;
DESCRIBE tbl_comments;

SELECT * FROM tbl_posts;
SELECT * FROM tbl_users_account;
SELECT * FROM tbl_users_notification t1 JOIN tbl_users_account t2 ON t1.recipient_id = t2.user_id;
SELECT * FROM tbl_groups;
SELECT * FROM tbl_users_connection;
SELECT * FROM tbl_post_comments;

SELECT * FROM tbl_posts;
SET @post_id = 2;
INSERT INTO tbl_post_tags(post_id, user_id) 
SELECT 
	@post_id post_id,
	user_id user_id
FROM tbl_users_account 
WHERE username IN ('student1', 'student2');
SELECT * FROM tbl_post_tags; 

ROLLBACK;
COMMIT;
START TRANSACTION;

SELECT t1.group_id, t2.username, t1.is_group_moderator, t1.group_role FROM tbl_group_members t1 JOIN tbl_users_account t2 ON t1.member_id = t2.user_id;
-- PARAMETERS [15]
SET @group_id = NULL;
SET @post_id = 2;
SET @parent_comment_id = 3;
SET @user_id = (SELECT user_id FROM tbl_users_account WHERE username = 'student6');
SET @comment_text = 'child-comment!';
SET @mentioned_users_id = 'cf1099b6-471d-11f1-9a32-37b9fcc3dc05 cf109f4c-471d-11f1-9a32-37b9fcc3dc05 cf10a0d2-471d-11f1-9a32-37b9fcc3dc05';

-- SQL [15]
INSERT INTO tbl_post_comments(parent_comment_id, post_id, group_id, author_id, comment_text, comment_status)
SELECT
	@parent_comment_id parent_comment_id,
	@post_id post_id,
	@group_id group_id,
	@user_id author_id,
	@comment_text comment_text,
	CASE
		WHEN @group_id IS NULL AND t3.post_policy = 'public' THEN 'posted'
		WHEN @group_id IS NULL AND t3.post_policy = 'moderated' AND t1.ROLE = 'student' AND t1.is_moderator = FALSE THEN 'pending'
		WHEN @group_id IS NULL AND t3.post_policy = 'moderated' AND (t1.ROLE IN ('instructor', 'admin') OR t1.is_moderator = TRUE) THEN 'posted'
		WHEN @group_id IS NULL AND t3.post_policy = 'restricted' AND t1.ROLE = 'admin' THEN 'posted'
		WHEN @group_id IS NOT NULL AND t3.post_policy = 'public' THEN 'posted'
		WHEN @group_id IS NOT NULL AND t3.post_policy = 'moderated' AND (t2.group_role != 'group_author' AND t2.is_group_moderator = FALSE) THEN 'pending'
		WHEN @group_id IS NOT NULL AND t3.post_policy = 'moderated' AND (t2.group_role = 'group_author' OR t2.is_group_moderator = TRUE) THEN 'posted'
		WHEN @group_id IS NOT NULL AND t3.post_policy = 'restricted' AND t2.group_role = 'group_author' THEN 'posted'
		ELSE 'pending'
	END comment_status
FROM tbl_users_account t1
LEFT JOIN tbl_group_members t2
	ON @group_id IS NOT NULL
	AND t2.group_id = @group_id
	AND t2.member_id = @user_id
JOIN tbl_portal_policy t3
	ON t3.policy_id = 1
WHERE t1.user_id = @user_id;

SET @comment_id = LAST_INSERT_ID();

INSERT INTO tbl_post_comment_mentions(comment_id, user_id)
SELECT
	@comment_id comment_id,
	t1.user_id user_id
FROM (
	WITH RECURSIVE recursion AS (
		SELECT 
			TRIM(REGEXP_REPLACE(CONVERT(@mentioned_users_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')) AS remaining, 
			SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(CONVERT(@mentioned_users_id USING utf8mb4), '[^a-zA-Z0-9\-]+', ' ')), ' ', 1) AS element
		UNION ALL
		SELECT
			TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), 
			SUBSTRING_INDEX(TRIM(SUBSTRING(remaining, CHAR_LENGTH(element) + 1)), ' ', 1)
		FROM recursion
		WHERE remaining != element AND remaining != ''
	)
	SELECT
		element AS user_id
	FROM recursion t1
	LEFT JOIN tbl_users_notification_mutes t2
		ON t1.element = t2.user_id
		AND t2.post_id = @post_id
		AND t2.comment_id = @comment_id
	WHERE t2.post_id IS NULL
	AND t2.comment_id IS NULL
) t1
LEFT JOIN tbl_users_notification_mutes t2
	ON t1.user_id = t2.user_id
	AND t2.post_id = @post_id
	AND t2.comment_id = @comment_id
WHERE t2.post_id IS NULL
AND t2.comment_id IS NULL;

SET @first_mention_id = (LAST_INSERT_ID() - ROW_COUNT());

INSERT INTO tbl_users_notification(sender_id, recipient_id, notification_type, notification_text, target_url, group_id, post_id, comment_id)
SELECT
	@user_id sender_id,
	tu.recipient_id recipient_id,
	tu.notification_type notification_type,
	CASE 
		WHEN tu.notification_type = 'MENTIONED_YOU_IN_COMMENT' THEN CONCAT(t1.full_name, ' mentioned you in a comment')
		WHEN tu.notification_type = 'COMMENTED_YOUR_POST' THEN CONCAT(t1.full_name, ' commented on your post')
		WHEN tu.notification_type = 'COMMENTED_ON_A_POST_THAT_YOU_ARE_TAGGED' THEN CONCAT(t1.full_name, ' commented on a post that you are tagged')
		WHEN tu.notification_type = 'REPLIED_YOUR_COMMENT' THEN CONCAT(t1.full_name, ' replied to your comment')
	END notification_text,
	CASE 
		WHEN @group_id IS NOT NULL THEN CONCAT('group/', @group_id , '/post/', @post_id, '/comment/', @comment_id)
		ELSE CONCAT('post/', @post_id, '/comment/', @comment_id)
	END target_url,
	@group_id group_id,
	@post_id post_id,
	@comment_id comment_id
FROM (
	SELECT
		'MENTIONED_YOU_IN_COMMENT' notification_type,
		t1.user_id recipient_id
	FROM tbl_post_comment_mentions t1
	LEFT JOIN tbl_users_notification_mutes t2
		ON t1.user_id = t2.user_id
		AND t2.post_id = @post_id
		AND t2.comment_id = @comment_id
	WHERE t2.post_id IS NULL
	AND t2.comment_id IS NULL
	AND t1.mention_id > @first_mention_id
	UNION ALL
	SELECT 
		'COMMENTED_YOUR_POST' notification_type,
		t1.author_id recipient_id
	FROM tbl_posts t1
	LEFT JOIN tbl_users_notification_mutes t2
		ON t1.author_id = t2.user_id
	LEFT JOIN tbl_post_comment_mentions t3
		ON t3.mention_id > @first_mention_id
		AND t1.author_id = t3.user_id
	WHERE @parent_comment_id IS NULL 
	AND t1.post_id = @post_id
	AND t2.post_id IS NULL
	AND t3.user_id IS NULL
	UNION ALL
	SELECT
		'COMMENTED_ON_A_POST_THAT_YOU_ARE_TAGGED' notification_type,
		t1.user_id recipient_id
	FROM tbl_post_tags t1
	LEFT JOIN tbl_users_notification_mutes t2
		ON t1.user_id = t2.user_id
	LEFT JOIN tbl_post_comment_mentions t3
		ON t3.mention_id > @first_mention_id
		AND t1.user_id = t3.user_id
	WHERE @parent_comment_id IS NULL
	AND t1.post_id = @post_id
	AND t2.post_id IS NULL
	AND t3.user_id IS NULL
	UNION ALL
	SELECT 
		'REPLIED_YOUR_COMMENT' notification_type,
		t1.author_id recipient_id
	FROM tbl_post_comments t1
	LEFT JOIN tbl_users_notification_mutes t2
		ON t1.author_id = t2.user_id
	LEFT JOIN tbl_post_comment_mentions t3
		ON t3.mention_id > @first_mention_id
		AND t3.user_id = t1.author_id
	WHERE @parent_comment_id IS NOT NULL
	AND t1.comment_id = @parent_comment_id
	AND t2.comment_id IS NULL
	AND t3.user_id IS NULL
) tu
JOIN tbl_users_profile t1
	ON t1.user_id = @user_id;

SET @starting_notification_id = (LAST_INSERT_ID() - ROW_COUNT());

SELECT 
	t1.notification_id, 
	t2.connection_id
FROM tbl_users_notification t1
JOIN tbl_users_connection t2
	ON t1.recipient_id = t2.user_id
WHERE t1.notification_id >= @starting_notification_id;