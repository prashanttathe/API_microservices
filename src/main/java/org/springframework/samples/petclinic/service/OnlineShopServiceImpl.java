package org.springframework.samples.petclinic.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.samples.petclinic.model.Cart;
import org.springframework.samples.petclinic.model.OrderSummary;
import org.springframework.samples.petclinic.model.Product;
import org.springframework.samples.petclinic.repository.jpa.CartRepository;
import org.springframework.samples.petclinic.repository.jpa.ProductRepository;
import org.springframework.stereotype.Service;

@Service
public class OnlineShopServiceImpl {

	@Autowired
	private ProductRepository productRepository;

	@Autowired
	private CartRepository cartRepository;

	public ResponseEntity<List<Product>> getProducts(){
		return new ResponseEntity<>(productRepository.findAll(), HttpStatus.OK);
	}

	public ResponseEntity<Cart> addToCart(Product product){
		Optional<Cart> cart =cartRepository.findById(product.getId());
		Cart crt = new Cart();
		if(cart.isPresent()) {
			crt = cart.get();
			crt.setQuantity(crt.getQuantity()+1);
		}
		else {
			crt.setId(product.getId());
			crt.setName(product.getName());
			crt.setAmount(product.getAmount());
			crt.setCurrency(product.getCurrency());
			crt.setQuantity(1);

		}		
		return new ResponseEntity<>(cartRepository.save(crt), HttpStatus.OK);
	}

	public ResponseEntity<OrderSummary> orderSummary(){

		List<Cart> cartLst = cartRepository.findAll();

		BigDecimal totalAmt = BigDecimal.ZERO;

		for(Cart crt:cartLst) {
			totalAmt=totalAmt.add(crt.getAmount().multiply(new BigDecimal(crt.getQuantity())));
		}

		return new ResponseEntity<>(new OrderSummary(cartLst,totalAmt), HttpStatus.OK);
	}
	
	public ResponseEntity<String> clearCart(){
		cartRepository.deleteAll();
		return new ResponseEntity<>("Cart empty.", HttpStatus.OK);
	}
}
