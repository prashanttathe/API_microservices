package org.springframework.samples.petclinic.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.samples.petclinic.model.Product;
import org.springframework.samples.petclinic.repository.jpa.ProductRepository;
import org.springframework.stereotype.Service;

@Service
public class OnlineShopServiceImpl {

	@Autowired
	private ProductRepository productRepository;
	
	public ResponseEntity<List<Product>> getProducts(){
		return new ResponseEntity<>(productRepository.findAll(), HttpStatus.OK);
	}
}
