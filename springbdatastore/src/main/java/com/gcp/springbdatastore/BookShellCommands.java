package com.gcp.springbdatastore;

import java.util.List;

import org.springframework.shell.standard.ShellComponent;
import org.springframework.shell.standard.ShellMethod;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gcp.springbdatastore.entity.Book;
import com.gcp.springbdatastore.repository.BookRepository;
import com.google.common.collect.Lists;

@ShellComponent
public class BookShellCommands {
  private final BookRepository bookRepository;
  private final ObjectMapper objectMapper;

  public BookShellCommands(BookRepository bookRepository, ObjectMapper objectMapper) {
    this.bookRepository = bookRepository;
    this.objectMapper = objectMapper;
  }

  @ShellMethod("Saves a book to Cloud Datastore using JSON")
  public String saveBook(String jsonContent) throws Exception {
    Book book = objectMapper.readValue(jsonContent, Book.class);
    return bookRepository.save(book).toString();
  }

  @ShellMethod("Loads all books")
  public String findAllBooks() {
    Iterable<Book> books = bookRepository.findAll();
    return Lists.newArrayList(books).toString();
  }

  @ShellMethod("Loads books by author: find-by-author <author>")
  public String findByAuthor(String author) {
    List<Book> books = bookRepository.findByAuthor(author);
    return books.toString();
  }

  @ShellMethod("Loads books published after a given year: find-by-year-after <year>")
  public String findByYearAfter(int year) {
    List<Book> books = bookRepository.findByYearGreaterThan(year);
    return books.toString();
  }

  @ShellMethod("Loads books by author and year: find-by-author-year <author> <year>")
  public String findByAuthorYear(String author, int year) {
    List<Book> books = bookRepository.findByAuthorAndYear(author, year);
    return books.toString();
  }

  @ShellMethod("Removes all books")
  public void removeAllBooks() {
    bookRepository.deleteAll();
  }
}