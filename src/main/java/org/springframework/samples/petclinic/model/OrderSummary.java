package org.springframework.samples.petclinic.model;

import java.math.BigDecimal;
import java.util.List;

public class OrderSummary {

	private List<Cart> cart;
	private BigDecimal totalAmount;
	public List<Cart> getCart() {
		return cart;
	}
	public void setCart(List<Cart> cart) {
		this.cart = cart;
	}
	public BigDecimal getTotalAmount() {
		return totalAmount;
	}
	public void setTotalAmount(BigDecimal totalAmount) {
		this.totalAmount = totalAmount;
	}
	public OrderSummary(List<Cart> cart, BigDecimal totalAmount) {
		super();
		this.cart = cart;
		this.totalAmount = totalAmount;
	}
	
	
	
	
}
