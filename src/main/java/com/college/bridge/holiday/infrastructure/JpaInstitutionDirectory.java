package com.college.bridge.holiday.infrastructure;

import com.college.bridge.holiday.application.port.InstitutionDirectory;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class JpaInstitutionDirectory implements InstitutionDirectory {

    private final InstitutionRepository institutionRepository;

    @Override
    public List<InstitutionRef> eligibleInstitutions() {
        return institutionRepository.findByStatus(InstitutionStatus.ACTIVE).stream()
                .map(inst -> new InstitutionRef(inst.getInstitutionId(), inst.getName(), inst.getRegion()))
                .toList();
    }

    @Override
    public String nameOf(Long institutionId) {
        return institutionRepository.findById(institutionId)
                .map(Institution::getName)
                .orElse("College");
    }
}
