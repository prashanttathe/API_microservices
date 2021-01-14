package org.springframework.samples.petclinic.rest;

import java.util.List;

import javax.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.samples.petclinic.model.Product;
import org.springframework.samples.petclinic.model.User;
import org.springframework.samples.petclinic.service.OnlineShopServiceImpl;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@RestController
@CrossOrigin(exposedHeaders = "errors, content-type")
@RequestMapping("api/shop")
public class OnlineShopController {

@Autowired
private OnlineShopServiceImpl onlineShopServiceImpl;

	@PreAuthorize( "hasRole(@roles.ADMIN)" )
	@GetMapping
	public ResponseEntity<List<Product>> getProducts(){
		return null;

	}

}
