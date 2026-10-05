package com.gcp.springbdatastore;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import com.gcp.springbdatastore.repository.BookRepository;

@SpringBootTest(properties = {
		"spring.cloud.gcp.datastore.enabled=false",
		"spring.shell.interactive.enabled=false"
})
class SpringbdatastoreApplicationTests {

	@MockitoBean
	private BookRepository bookRepository;

	@Test
	void contextLoads() {
	}

}
