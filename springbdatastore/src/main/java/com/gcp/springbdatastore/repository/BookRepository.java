package com.gcp.springbdatastore.repository;

import java.util.List;

import com.gcp.springbdatastore.entity.Book;
import com.google.cloud.spring.data.datastore.repository.DatastoreRepository;


public interface BookRepository extends DatastoreRepository<Book, Long> {

  List<Book> findByAuthor(String author);

  List<Book> findByYearGreaterThan(int year);

  List<Book> findByAuthorAndYear(String author, int year);
}
