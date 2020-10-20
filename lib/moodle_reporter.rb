require "moodle_reporter/version"
require "bundler/setup"
require "mysql2"

module MoodleReporter
  def self.grade
    client = Mysql2::Client.new(
      :host => ENV["DATABASE_HOST"],
      :username => ENV["DATABASE_USER"],
      :password => ENV["DATABASE_PASS"],
      :encoding => ENV["DATABASE_ENCODE"],
      :database => ENV["DATABASE_SCHEMA"],
    )
    sql = <<-"SQL"
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

    statement = client.prepare(sql)
    results = statement.execute()
    results.each do |row|
      puts row # {"id"=>1, "dep"=>1, "name"=>"hoge"}
    end
  end

  def self.feedback
    client = Mysql2::Client.new(
      :host => ENV["DATABASE_HOST"],
      :username => ENV["DATABASE_USER"],
      :password => ENV["DATABASE_PASS"],
      :encoding => ENV["DATABASE_ENCODE"],
      :database => ENV["DATABASE_SCHEMA"],
    )
    sql = <<-"SQL"
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

    statement = client.prepare(sql)
    results = statement.execute()
    results.each do |row|
      puts row # {"id"=>1, "dep"=>1, "name"=>"hoge"}
    end
  end

  def self.enrol
    client = Mysql2::Client.new(
      :host => ENV["DATABASE_HOST"],
      :username => ENV["DATABASE_USER"],
      :password => ENV["DATABASE_PASS"],
      :encoding => ENV["DATABASE_ENCODE"],
      :database => ENV["DATABASE_SCHEMA"],
    )
    sql = <<-"SQL"
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

    statement = client.prepare(sql)
    results = statement.execute()
    results.each do |row|
      puts row # {"id"=>1, "dep"=>1, "name"=>"hoge"}
    end
  end
end
