DROP TABLE IF EXISTS users;

CREATE TABLE users(
  id INTEGER PRIMARY KEY,
  f_name TEXT NOT NULL,
  l_name TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)

);


DROP TABLE IF EXISTS questions_follows;

CREATE TABLE questions_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
  FOREIGN KEY (question_id) REFERENCES questions(id)
);


DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  subject_id INTEGER NOT NULL,
  parent_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL,
  body TEXT NOT NULL,

  FOREIGN KEY (subject_id) REFERENCES questions(id)
  FOREIGN KEY (parent_id) REFERENCES replies(id)
  FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE questions_likes;

CREATE TABLE questions_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
  FOREIGN KEY (question_id) REFERENCES questions(id)

);


INSERT INTO
  users (f_name,l_name)
VALUES
  ('Zion','Wen'),
  ('Bryce','Williams'),
  ('David','Webber'),
  ('David','Jackson'),
  ('John','Webber'),
  ('David','Harris'),
  ('Arnold','Wexler');



  INSERT INTO
    questions (title,body,author_id)
  VALUES
    ('SQL questions','How do self joins work?', 2),
    ('Ruby SQL ORM','How do you manipulate SQL in Ruby?',2),
    ('Ruby SQL ORM','How do you manipulate SQL in Ruby?',2),
    ('Ruby SQL ORM','How do you manipulate SQL in Ruby?',2),
    ('Ruby SQL ORM','How do you manipulate SQL in Ruby?',1);


  INSERT INTO
    questions_follows (user_id,question_id)
  VALUES
    (2,1),
    (1,2),
    (5,1),
    (4,2),
    (4,1),
    (3,2);

  INSERT INTO
    replies (subject_id,parent_id,author_id,body)
  VALUES
    (2,1,3,"Thumbs up, I have the same question"),
    (2,1,1,"Cool lets meet up at App Academy and discuss"),
    (2,2,3,"Sounds good"),
    (1,1,5,"I don't understand what you're asking"),
    (1,1,2,"what's for supper after I do self joins"),
    (1,2,4,"Self joins make me hungry");

    INSERT INTO
      questions_likes (user_id, question_id)
    VALUES
      (1,2),
      (5,1),
      (4,1),
      (3,2),
      (2,1),
      (2,3),
      (4,5),
      (3,3),
      (5,4);
