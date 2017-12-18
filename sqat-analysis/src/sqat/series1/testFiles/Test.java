import java.util.ArrayList;

public abstract class Test {

	private final List<boolean> booleans;

	// McCabe complexity = 2 
	protected Test() {
		this.booleans = new ArrayList<>();
		for (int i = 0; i < 10; i++) {
			this.booleans[i] = (i % 2 == 0);
		}
	}

	// McCabe complexity = 12 
	public int testMethod1() {
		int x = 0;
		for (int i = 0; i < 8; i++) {
			if (true) {
				if (true) {
					if (this.booleans.isEmpty()) {
						x = i;						
					}
				}
				if (false && !this.booleans.isEmpty()) {
					x = -i;
				}
			} else {
				x = 9;
			}
		}
		return x;
	}
	
	// McCabe complexity = 14
	public int testMethod2() {
		int x = 0;
		if ((1 == 2 && true) && this.booleans.isEmpty()) {
			if (true) {
				if (this.booleans.isEmpty()) {
					x = i;						
				}
			}
			if (false && !this.booleans.isEmpty()) {
				x = -i;
			}
		} else {
			x = 9;
		}
		return x;
	}

	// McCabe complexity = 12
	public int testMethod3() {
		int x = 0;
		if (true) {
			if (1 == 2 && true && this.booleans.isEmpty()) {
				x = i;						
			}
			if (false && !this.booleans.isEmpty()) {
				x = -i;
			}
		} else {
			x = 9;
		}
		return x;
	}
	
	// McCabe complexity = 14
	public void testMethod4() {
		int x = 0;
		if (1 == 2 && (true && this.booleans.isEmpty())) {
			if (true) {
				if (this.booleans.isEmpty()) {
					x = i;
				}
			}
			if (false && !this.booleans.isEmpty()) {
				x = -i;
			}
		} else {
			x = 9;
		}
	}
	
	// McCabe complexity = 8  
	public int testMethod5() {
		int x = 0;
		for (int i = 0; i < 8; i++) {
			if (true) {
				if (false && !this.booleans.isEmpty()) {
					x = -i;
				}
			} else {
				x = 9;
			}
		}
		return x;
	}
}
