package com.gcp.springbdatastore;

import java.util.List;
import java.util.Objects;

import org.springframework.shell.core.command.annotation.Argument;
import org.springframework.shell.core.command.annotation.Command;
import org.springframework.stereotype.Component;

import com.gcp.springbdatastore.entity.Book;
import com.gcp.springbdatastore.repository.BookRepository;
import com.google.common.collect.Lists;

import tools.jackson.databind.ObjectMapper;

@Component
public class BookShellCommands {
  private final BookRepository bookRepository;
  private final ObjectMapper objectMapper;

  public BookShellCommands(BookRepository bookRepository, ObjectMapper objectMapper) {
    this.bookRepository = bookRepository;
    this.objectMapper = objectMapper;
  }

  @Command(name = "save-book", description = "Saves a book to Cloud Datastore using JSON")
  public String saveBook(@Argument(index = 0) String jsonContent) throws Exception {
    Book book = objectMapper.readValue(jsonContent, Book.class);
    return bookRepository.save(book).toString();
  }

  @Command(name = "find-all-books", description = "Loads all books")
  public String findAllBooks() {
    Iterable<Book> books = Objects.requireNonNull(bookRepository.findAll());
    return Lists.newArrayList(books).toString();
  }

  @Command(name = "find-by-author", description = "Loads books by author")
  public String findByAuthor(@Argument(index = 0) String author) {
    List<Book> books = bookRepository.findByAuthor(author);
    return books.toString();
  }

  @Command(name = "find-by-year-after", description = "Loads books published after a given year")
  public String findByYearAfter(@Argument(index = 0) int year) {
    List<Book> books = bookRepository.findByYearGreaterThan(year);
    return books.toString();
  }

  @Command(name = "find-by-author-year", description = "Loads books by author and year")
  public String findByAuthorYear(@Argument(index = 0) String author, @Argument(index = 1) int year) {
    List<Book> books = bookRepository.findByAuthorAndYear(author, year);
    return books.toString();
  }

  @Command(name = "remove-all-books", description = "Removes all books")
  public void removeAllBooks() {
    bookRepository.deleteAll();
  }
}