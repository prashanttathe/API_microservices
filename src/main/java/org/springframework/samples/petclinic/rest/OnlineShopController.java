package org.springframework.samples.petclinic.rest;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.samples.petclinic.model.Cart;
import org.springframework.samples.petclinic.model.OrderSummary;
import org.springframework.samples.petclinic.model.Product;
import org.springframework.samples.petclinic.service.OnlineShopServiceImpl;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@CrossOrigin(exposedHeaders = "errors, content-type")
@RequestMapping("api/shop")
public class OnlineShopController {

@Autowired
private OnlineShopServiceImpl onlineShopServiceImpl;

	//@PreAuthorize( "hasRole(@roles.ADMIN)" )
	@GetMapping("/getproducts")
	public ResponseEntity<List<Product>> getProducts(){
		return onlineShopServiceImpl.getProducts();
	}
	
	@PostMapping("/addtocart")
	public ResponseEntity<Cart> addToCart(@RequestBody Product product){
		return onlineShopServiceImpl.addToCart(product);
	}
	
	@GetMapping("/ordersummary")
	public ResponseEntity<OrderSummary> orderSummary(){
		return onlineShopServiceImpl.orderSummary();
	}
	
	@DeleteMapping("/clearcart")
	public ResponseEntity<String> clearCart(){
		return onlineShopServiceImpl.clearCart();
	}

}
