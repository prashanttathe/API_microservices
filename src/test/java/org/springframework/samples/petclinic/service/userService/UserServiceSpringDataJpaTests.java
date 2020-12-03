package org.springframework.samples.petclinic.service.userService;

import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
//import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

import io.cucumber.junit.Cucumber;
import io.cucumber.junit.CucumberOptions;

@RunWith(Cucumber.class)
@CucumberOptions(features = "src/test/resources/features/bagextra",
        plugin = {"pretty", "html:target/cucumber/bagextra"},
        extraGlue = "io.tpd.springbootcucumber.bagcommons")

@SpringBootTest
//@RunWith(SpringJUnit4ClassRunner.class)
@ActiveProfiles("spring-data-jpa, hsqldb")

public class UserServiceSpringDataJpaTests extends AbstractUserServiceTests {

}
