require "moodle_reporter/version"
require "bundler/setup"
require "mysql2"

module MoodleReporter
  SQL_GRADE = <<-SQL
SELECT
  u.id                         AS user_id,
  u.email                      AS user_email,
  c.id                         AS course_id,
  c.fullname                   AS course_name,
  gi.id                        AS item_id,
  gi.itemname                  AS item_name,
  gg.id                        AS grade_id,
  CAST(gi.gradepass AS CHAR)   AS grade_pass,
  CAST(gg.finalgrade AS CHAR)  AS final_grade,
  FROM_UNIXTIME(gg.timecreated+9*60*60, '%Y-%m-%d')               AS time_created,
  FROM_UNIXTIME(gg.timemodified+9*60*60, '%Y-%m-%d')              AS time_modified
FROM
  mdl_grade_grades AS gg INNER JOIN
  mdl_user         AS u  ON u.id = gg.userid INNER JOIN
  mdl_grade_items  AS gi ON gi.id = gg.itemid INNER JOIN
  mdl_course       AS c  ON c.id = gi.courseid
WHERE
  gi.itemtype = 'mod' AND 
  gi.hidden = 0 AND
  c.visible = 1
ORDER BY u.id, c.id, gi.id, gg.id   
SQL

  SQL_FEEDBACK = <<-SQL
SELECT
  u.id            AS user_id,
  u.email         AS user_email,
  c.id            AS course_id,
  c.fullname      AS course_name,
  f.id            AS feedback_id,
  f.name          AS feedback_name,
  f.anonymous     AS anonymous,
  FROM_UNIXTIME(fc.timemodified+9*60*60) AS time_modified
FROM
  mdl_feedback           AS f  INNER JOIN
  mdl_course             AS c  ON c.id = f.course INNER JOIN
  mdl_feedback_completed AS fc ON fc.feedback = f.id INNER JOIN
  mdl_user               AS u  ON u.id = fc.userid
ORDER BY u.id, c.id, f.id
SQL

  SQL_ENROL = <<-SQL
SELECT DISTINCT
  u.id       AS user_id,
  u.email    AS user_email,
  c.id       AS course_id,
  c.fullname AS course_name,
  e.roleid   AS role_id,
  r.name     AS role_name
FROM
  mdl_user_enrolments AS ue INNER JOIN
  mdl_user            AS u  ON u.id = ue.userid  INNER JOIN
  mdl_enrol           AS e  ON ue.enrolid = e.id INNER JOIN
  mdl_course          AS c  ON e.courseid = c.id INNER JOIN
  mdl_role            AS r  ON e.roleid = r.id
ORDER BY u.id, c.id, e.roleid
SQL

  SQL_COURSE_SETTINGS = <<-SQL
SELECT
  id,
  fullname,
  shortname,
  FROM_UNIXTIME(startdate+9*60*60,'%Y-%m-%d') AS startdate,
  FROM_UNIXTIME(enddate+9*60*60,'%Y-%m-%d') AS enddate,
  visible,
  enablecompletion
FROM
  mdl_course
SQL

  SQL_FEEDBACK_SETTINGS = <<-SQL
SELECT
  c.id AS course_id,
  c.fullname AS course_name,
  f.id AS fb_id,
  f.name AS fb_name,
  f.anonymous AS fb_anon,
  f.multiple_submit AS fb_multi_submit,
  FROM_UNIXTIME(f.timeopen+9*60*60, '%Y-%m-%d') AS fb_open,
  FROM_UNIXTIME(f.timeclose+9*60*60, '%Y-%m-%d') AS fb_close,
  f.completionsubmit AS fb_completion
FROM
  mdl_course AS c LEFT OUTER JOIN
  mdl_feedback f ON c.id = f.course
SQL

  SQL_QUIZ_SETTINGS = <<-SQL
SELECT
  c.id AS course_id,
  c.fullname AS course_name,
  q.id,
  q.name,
  FROM_UNIXTIME(q.timeopen+9*60*60,'%Y-%m-%d') AS timeopen,
  FROM_UNIXTIME(q.timeclose+9*60*60,'%Y-%m-%d') AS timeclose,
  q.timelimit,
  q.canredoquestions,
  q.shuffleanswers,
  q.sumgrades,
  q.grade,
  q.completionattemptsexhausted,
  q.completionpass
FROM
  mdl_course AS c LEFT OUTER JOIN
  mdl_quiz q ON c.id = q.course
SQL

  class Reporter
    attr_reader :client

    def initialize
      @client = Mysql2::Client.new(
        :host => ENV["DATABASE_HOST"],
        :username => ENV["DATABASE_USER"],
        :password => ENV["DATABASE_PASS"],
        :encoding => ENV["DATABASE_ENCODE"],
        :database => ENV["DATABASE_SCHEMA"],
      )
    end

    def grade
      statement = @client.prepare(SQL_GRADE)
      return statement.execute()
    end

    def feedback
      statement = @client.prepare(SQL_FEEDBACK)
      return statement.execute()
    end

    def enrol
      statement = @client.prepare(SQL_ENROL)
      return statement.execute()
    end

    def course_settings
      statement = @client.prepare(SQL_COURSE_SETTINGS)
      return statement.execute()
    end

    def quiz_settings
      statement = @client.prepare(SQL_QUIZ_SETTINGS)
      return statement.execute()
    end

    def feedback_settings
      statement = @client.prepare(SQL_FEEDBACK_SETTINGS)
      return statement.execute()
    end

    def print(rows)
      rows.each do |row|
        puts row # {"id"=>1, "dep"=>1, "name"=>"hoge"}
      end
    end

    def learning_progress
    end
  end
end
