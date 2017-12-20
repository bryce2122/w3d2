require 'sqlite3'
require 'singleton'

class PlayDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end














class User
  attr_accessor :f_name, :l_name
  attr_reader :id

  METHODS = ["find_by_f_name"]

  def self.all
    data = PlayDBConnection.instance.execute("SELECT * FROM users")
    data.map {|datum| User.new(datum)}
  end


  def self.find_by_f_name(f_name)
    user = PlayDBConnection.instance.execute(<<-SQL, f_name)
      SELECT
        *
      FROM
        users
      WHERE
        f_name = ?
    SQL

    return nil if user.empty?
    user.map {|us| User.new(us)}
  end


  def self.where(options)
    results = []
    options.each do |k,v|
      method = "find_by_#{k}"
      if METHODS.include?(method)

        results << self.send(method,v) unless self.send(method,v).nil?
      end
    end
    results
  end



  def self.find_by_name(f_name,l_name)
    user = PlayDBConnection.instance.execute(<<-SQL, f_name,l_name)
      SELECT
        *
      FROM
        users
      WHERE
        f_name = ? AND  l_name = ?
    SQL

    return nil if user.empty?
    user.map {|us| User.new(us)}
  end

  def initialize(options)
    @id = options['id']
    @f_name = options['f_name']
    @l_name = options['l_name']
  end

  def average_karma
    average_karma = PlayDBConnection.instance.execute(<<-SQL, id)
    SELECT
      COUNT(*) / COUNT(DISTINCT (question_id))
    FROM
      users
    JOIN
      questions
      ON
      users.id = author_id
    JOIN
      questions_likes
      ON
      question_id = questions.id
    WHERE
      author_id = ?

    SQL

    average_karma.first

  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(id)
  end

  def authored_questions
    Question.find_by_author_id(id)
  end

  def authored_replies
    Reply.find_by_user_id(id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(id)
  end

  def create
    raise "#{self} already in database" if @id
    PlayDBConnection.instance.execute(<<-SQL, @f_name, @l_name)
      INSERT INTO
        users (f_name,l_name)
      VALUES
        (?,?)
    SQL
    @id = PlayDBConnection.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    PlayDBConnection.instance.execute(<<-SQL, @f_name, @l_name, @id)
      UPDATE
        users
      SET
        f_name = ?, l_name = ?
      WHERE
        id = ?
    SQL
  end

end

class Question
  attr_accessor :title, :body, :author_id
  attr_reader :id

  def self.all
    data = PlayDBConnection.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
  end

  def self.find_by_author_id(author_id)
    author = PlayDBConnection.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL

    return nil if author.empty?

    author.map {|auth| Question.new(auth)}

  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_likeed_questions(n)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def likers
    QuestionLike.likers_for_question_id(id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(id)

  end



  def author
    author = PlayDBConnection.instance.execute(<<-SQL, @author_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL

    User.new(author.first)
  end

  def replies
    Reply.find_by_question_id(id)


  end

  def followers
    QuestionFollow.followers_for_question_id(id)
  end

  def create
    raise "#{self} already in database" if @id
    PlayDBConnection.instance.execute(<<-SQL, @title, @body, @author_id)
      INSERT INTO
        questions (title, body, author_id)
      VALUES
        (?,?,?)
    SQL
    @id = PlayDBConnection.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    PlayDBConnection.instance.execute(<<-SQL, @title, @body, @author_id, @id)
      UPDATE
        questions
      SET
        title = ?, body = ?, author_id = ?
      WHERE
        id = ?
    SQL
  end

end

class QuestionFollow
  attr_accessor :user_id, :question_id

  def self.all
    data = PlayDBConnection.instance.execute("SELECT * FROM users")
    data.map {|datum| User.new(datum)}
  end

  def self.most_followed_questions(n)

    data = PlayDBConnection.instance.execute(<<-SQL)
      SELECT
          questions.id, title, body, author_id
      FROM
        questions_follows
      JOIN
        questions ON question_id = questions.id
      GROUP BY question_id

      ORDER BY COUNT(question_id) DESC;


    SQL

    data.map {|quest| Question.new(quest)}.take(n)


  end




  def self.followers_for_question_id(question_id)
    followers = PlayDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        users.id, f_name, l_name
      FROM
        users
      JOIN
        questions_follows
        ON user_id = users.id
      WHERE
        question_id = ?
    SQL
    followers.map { |follower| User.new(follower) }
  end

  def self.followed_questions_for_user_id(user_id)
    questions = PlayDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id, title, body, author_id
      FROM
        questions
      JOIN
        questions_follows
        ON question_id = questions.id
      WHERE
        user_id = ?
    SQL
    questions.map { |question| Question.new(question) }
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def create
    raise "#{self} already in database" if @id
    PlayDBConnection.instance.execute(<<-SQL, @user_id, @question_id)
      INSERT INTO
        questions_follows (user_id,question_id)
      VALUES
        (?,?)
    SQL
    @id = PlayDBConnection.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    PlayDBConnection.instance.execute(<<-SQL, @user_id, @question_id, @id)
      UPDATE
        questions_follows
      SET
        user_id = ?, question_id = ?
      WHERE
        id = ?
    SQL
  end

end

class QuestionLike
  attr_accessor :user_id, :question_id

  def self.all
    data = PlayDBConnection.instance.execute("SELECT * FROM quesion")
    data.map {|datum| QuestionLike.new(datum)}
  end

  def self.num_likes_for_question_id (question_id)
    liker = PlayDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(question_id)
      FROM
        questions_likes
      WHERE
        question_id = ?
    SQL

    liker.first.to_a.last.last
end

  def self.liked_questions_for_user_id(user_id)
    question = PlayDBConnection.instance.execute(<<-SQL, user_id)
    SELECT
      question.id,title,body,author_id
    FROM
      questions_likes
    JOIN
      questions ON questions.id = question_id
    WHERE
      user_id = ?
    SQL

    question.map {|q| Question.new(q)}


  end

  def self.likers_for_question_id(question_id)
    likers = PlayDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        users.id, f_name, l_name
      FROM
        users
      JOIN
        questions_likes
        ON user_id = users.id
      WHERE
        question_id = ?
    SQL
    likers.map { |liker| User.new(liker) }
  end

  def self.most_likeed_questions(n)

    data = PlayDBConnection.instance.execute(<<-SQL)
      SELECT
          questions.id, title, body, author_id
      FROM
        questions_likes
      JOIN
        questions ON question_id = questions.id
      GROUP BY question_id

      ORDER BY COUNT(question_id) DESC;


    SQL

    data.map {|quest| Question.new(quest)}.take(n)


  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def create
    raise "#{self} already in database" if @id
    PlayDBConnection.instance.execute(<<-SQL, @user_id, @question_id)
      INSERT INTO
        quesion (user_id,question_id)
      VALUES
        (?,?)
    SQL
    @id = PlayDBConnection.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    PlayDBConnection.instance.execute(<<-SQL, @user_id, @question_id, @id)
      UPDATE
        quesion
      SET
        user_id = ?, question_id = ?
      WHERE
        id = ?
    SQL
  end

end

class Reply
  attr_accessor :subject_id, :parent_id, :author_id, :body

  def self.all
    data = PlayDBConnection.instance.execute("SELECT * FROM replies")
    data.map {|datum| Reply.new(datum)}
  end


  def self.find_by_user_id(user_id)
    user = PlayDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        author_id = ?
    SQL

    return nil if user.empty?

    user.map {|us| Reply.new(us)}


  end

  def self.find_by_question_id(question_id)
    question = PlayDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    return nil if question.empty?

    question.map {|us| User.new(us)}


  end

  def initialize(options)
    @id = options['id']
    @subject_id = options['subject_id']
    @parent_id = options['parent_id']
    @author_id = options['author_id']
    @body = options['body']
  end

  def create
    raise "#{self} already in database" if @id
    PlayDBConnection.instance.execute(<<-SQL, @subject_id, @parent_id, @author_id, @body)
      INSERT INTO
        replies (subject_id, parent_id, author_id, body)
      VALUES
        (?, ?, ?, ?)
    SQL
    @id = PlayDBConnection.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    PlayDBConnection.instance.execute(<<-SQL, @subject_id, @parent_id, @author_id, @body, @id)
      UPDATE
        replies
      SET
        subject_id = ?, parent_id = ?, author_id = ?, body = ?
      WHERE
        id = ?
    SQL
  end

  def author
    author = PlayDBConnection.instance.execute(<<-SQL, @author_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL

    User.new(author.first)
  end

  def question
    question = PlayDBConnection.instance.execute(<<-SQL, @subject_id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL

    Question.new(question.first)

  end


  def parent_reply
    parent = PlayDBConnection.instance.execute(<<-SQL, @parent_id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL

    Reply.new(parent.first)

  end

  def child_reply
  parent = PlayDBConnection.instance.execute(<<-SQL, @id)
  SELECT
    *
  FROM
    replies
  WHERE
    parent_id = ? AND id != parent_id
SQL
  return nil if parent.empty?
  Reply.new(parent.first)
end

end
